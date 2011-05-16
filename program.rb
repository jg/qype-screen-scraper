#!/usr/bin/env ruby
# encoding: utf-8

# scrapi would be even better but has 64bit issues
# require 'scrapi'
require 'net/http'
require 'uri'
require 'open-uri'
require 'nokogiri'
require 'date'
require 'sequel'

require 'ruby-debug'


class Review
  attr_accessor :body, :rating, :user, :date, :url, :qtype_id
  
  def to_s
    "#{user}@#{date}"
  end
end


class ReviewPack 
  ## Model for set of reviews from given place
  HOST = 'http://www.qype.com'
  MONTHNAMES =  %w(Januar Februar März April Mai Juni Juli August September Oktober November Dezember)
  DB_FILE = 'reviews.db'

  attr_accessor :reviews, :newest_comment

  def initialize
    @reviews = Array.new
  end

  def get_page(url) 
    ## Get page body
    uri = URI.parse(url)
    Net::HTTP.new(uri.host).request_get(uri.to_s).body
  end


  def pages_urls(url)
    ## Construct & Return array of urls of comment pages found on site at given url
    urls = Array.new

    urls << url

    doc = Nokogiri::HTML(open(url))
    last_page = doc.css('#PlaceReviews > p > a').each do |node|
      if node['href'] == '#' and not node['class'] == 'next_page'
        urls << HOST + node['onclick'].match(/asyncRequest[\(]'post', '(.+)',/)[1]
      end
    end 

    urls
  end

  def from_url(url)
    @url = url
    @id = url.match('/place/(\d+)')[1]

    ## Builds ReviewPack from given url
    pages_urls(url).each do |page_url| 
      @reviews.concat(get_reviews(get_page(page_url)))
    end

    # @newest_comment = @reviews.first 
  end

  def from_id(id)
    ## Builds ReviewPack from given qtype ID
    from_url(HOST + "/places/" + id.to_s)
  end

  def get_reviews(html)
    ## Extracts reviews from given site body, returns array of review objects
    reviews = Array.new

    doc = Nokogiri::HTML(html)
    doc.css('.ReviewBoxV2').each do |node|
      r = Review.new
      r.body   = node.at_css('.ReviewTextV2').text().strip()
      r.rating = node.at_css('.rating').text().strip()
      r.user   = node.at_css('.ContentUserPhotoBox > p > a').text()

      # Extract date
      day, month, year  = node.at_css('.PlaceReviewMeta').text().split(" ")[-3,3]
      day = day.to_i
      month = MONTHNAMES.index(month).to_i + 1
      year = year.to_i
      r.date = Date.civil(year, month, day)

      r.qtype_id = @id
      r.url = @url

      reviews << r
    end
    reviews
  end

  def get_from_db(id)
    ## G
  end

  def this.run(input)
    if input.match(/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix)
      from_url(input)
    else
      from_id(input)
    end
    
    if newer?(@reviews)
    end
  end
  def save
    db = Sequel.sqlite(DB_FILE)
    ds = db[:reviews]
    @reviews.each do |r|
      ds.insert(
        :url  => r.url,
        :body => r.body,
        :qtype_id => r.qtype_id,
        :rating => r.rating,
        :user => r.user,
        :date => r.date
      )
    end
  end
end


sample = 'http://www.qype.com/place/13080-Bar-Gagarin-Berlin'
r = ReviewPack.new

reviews = r.from_url(sample)
# debugger
# puts "ENDE"

