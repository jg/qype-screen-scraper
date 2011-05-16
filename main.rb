#!/usr/bin/env ruby
require './review_pack.rb'

## Main 
def main
  if ARGV.count != 1 
    print_usage
    exit
  end

  rp = ReviewPack.new

  input = ARGV[0]
  # Test if valid URL 
  if input.match(/^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$/ix) and input.match('/place/(\d+)')
    rp.from_url(input)
  elsif input.match(/^(\d+)$/) # Test if valid number
    rp.from_id(input)
  else
    print_usage
  end

  rp.save
end


def print_usage
  puts "Usage: "
  puts "\t ruby main.rb [URL|QTYPE_ID]"
  exit
end



main

