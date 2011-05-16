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
  attr_reader :body, :rating, :user, :date, :url, :qtype_id
  
  # def initialize(
  def initialize(args)
    args.each do |k,v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end unless args.nil?
  end

  def to_s
    "[#{user}@#{date}] writes \"#{body.delete('\n')}\"\n--"
  end

  def to_hash
    h = Hash.new
    instance_variables.each do |var|
      h[var.to_s.delete("@")] = instance_variable_get(var)
    end
    h
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
    ## Builds ReviewPack from given url
    @url = url
    @id = url.match('/place/(\d+)')[1]

    pages_urls(url).each do |page_url| 
      @reviews.concat(get_reviews(get_page(page_url)))
    end
    # puts "Found #{@reviews.count} reviews on #{url} :"

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
      h['rating'] = node.at_css('.rating').text().strip()
      h['user']   = node.at_css('.ContentUserPhotoBox > p > a').text()

      # Extract date
      day, month, year  = node.at_css('.PlaceReviewMeta').text().split(" ")[-3,3]
      day = day.to_i
      month = MONTHNAMES.index(month).to_i + 1
      year = year.to_i
      h['date'] = Date.civil(year, month, day)

      h['qtype_id'] = @id
      h['url'] = @url



      reviews << Review.new(h)
    end
    reviews
  end

  def newest_review
    @reviews.max{|r| r.date}
  end

  def save
    return if @reviews.count == 0

    db = Sequel.sqlite(DB_FILE)
    ds = db[:reviews]
    db_newest_review = Review.new(ds.where(:qtype_id => @id).order(:date).reverse.first)
    # puts db_newest_review.date
    # debugger

    no_entries = 0
    if db_newest_review.date != nil
      # puts "db_newest_review != nil"
      if newest_review.date > db_newest_review.date 
        # Update DB with new records  
        @reviews.each do |r|
          if r.date > db_newest_review.date
            puts r
            ds.insert(r.to_hash)
            no_entries = no_entries + 1
          end
        end
      end
    else
      # puts "db_newest_review == nil"
      # No entry in db, save all records
      @reviews.each do |r|
        puts r
        ds.insert(r.to_hash) 
        no_entries = no_entries + 1
      end unless @reviews.nil?
    end 
    puts "Added #{no_entries} new records from #{@url}"
  end
end


if ARGV.count != 1 
  puts "Usage: "
  puts "\t./program [URL|QTYPE_ID]"
  exit
end
rp = ReviewPack.new
input = ARGV[0]
if input.match(/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix)
  rp.from_url(input)
else
  rp.from_id(input)
end
rp.save

# sample = 'http://www.qype.com/place/13080-Bar-Gagarin-Berlin'
# r = ReviewPack.new
# 
# reviews = r.from_url(sample)
# debugger
# puts "ENDE"

