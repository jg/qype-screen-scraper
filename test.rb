require 'test/unit'
require './review_pack.rb'

class ReviewPackTest < Test::Unit::TestCase
	def test_review_number_match
	  # Tests whether no. of found reviews matches the no. displayed on page
	  # It appears the site has inconsistencies which make this test not very effective
    # http://www.qype.com/place/754709 
    # http://www.qype.com/place/277760
		id = 100+rand(1000000)
		r = ReviewPack.new
		r.from_id(id)

    url = 'http://www.qype.com/place/' + id.to_s
    doc = Nokogiri::HTML(open(url))
    assert_equal(doc.css('#Content strong.count').text().to_i, r.reviews.size)
    # assert_equal(, size)

	end
end
