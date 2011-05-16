#!/usr/bin/env ruby
# encoding: utf-8
require 'nokogiri' # scrapi would be even better but has 64bit issues
require 'net/http'
require 'uri'
require 'open-uri'
require 'date'
require 'sequel'
require 'ruby-debug'
require './review.rb'

DB_FILE = 'reviews.db'

class ReviewPack 
  ## Model for set of reviews from given place
  HOST = 'http://www.qype.com'
  MONTHNAMES =  %w(Januar Februar März April Mai Juni Juli August September Oktober November Dezember)

  attr_reader :reviews

  def initialize
    @reviews = Array.new
  end

  def get_page(url) 
    ## Get page body
    uri = URI.parse(url)
    begin
      Net::HTTP.new(uri.host).request_get(uri.to_s).body
      rescue Exception => e
       puts e.message
       exit
    end
  end

  def pages_urls(url)
    ## Construct & Return array of urls of comment pages found on site at given url
    urls = Array.new
    urls << url

    doc = Nokogiri::HTML(get_page(url))
    last_page = doc.css('#PlaceReviews > p > a').each do |node|
      if node['href'] == '#' and not node['class'] == 'next_page'
        urls << HOST + node['onclick'].match(/asyncRequest[\(]'post', '(.+)',/)[1]
      end
    end 

    urls
  end

  def from_url(url)
    ## Builds ReviewPack from given url
    @url = url
    @id = url.match('/place/(\d+)')[1]

    pages_urls(url).each do |page_url| 
      @reviews.concat(get_reviews(get_page(page_url)))
    end
    puts "Found #{@reviews.count} reviews on #{url}\n--"
  end

  def from_id(id)
    ## Builds ReviewPack from given qtype ID
    host = HOST + "/place/" + id.to_s
    from_url(host)
  end

  def get_reviews(html)
    ## Extracts reviews from given site body, returns array of review objects
    reviews = Array.new

    doc = Nokogiri::HTML(html)
    doc.css('.ReviewBoxV2').each do |node|
      h = Hash.new

      h['body']   = node.at_css('.ReviewTextV2').text().strip()
      # It seems rating isn't always shown
      unless node.at_css('.rating').nil?
				h['rating'] = node.at_css('.rating').text().strip()
			else
				h['rating'] = 0
			end
      h['user']   = node.at_css('.ContentUserPhotoBox > p > a').text()

      # Extract date
      day, month, year  = node.at_css('.PlaceReviewMeta').text().split(" ")[-3,3]
      day = day.to_i
      month = MONTHNAMES.index(month).to_i + 1
      year = year.to_i
      h['date'] = Date.civil(year, month, day)

      h['qtype_id'] = @id

      reviews << Review.new(h)
    end
    reviews
  end

  def save 
    ## Saves new reviews to DB
    return if @reviews.count == 0

    ds = Sequel.sqlite(DB_FILE)[:reviews]

    no_entries = 0
    @reviews.each do |r|
      unless r.in_db?
         puts r
         ds.insert(r.to_hash)
         no_entries = no_entries + 1
      end
    end
    
    puts "Added #{no_entries} new records from #{@url}"
  end
end

