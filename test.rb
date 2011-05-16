require 'test/unit'
require './review_pack.rb'

class ReviewTest < Test::Unit::TestCase
	def test
		assert_equal(13, 13)
	end
end

class ReviewPackTest < Test::Unit::TestCase
	def test_nonexistent_page_as_input
		id = 12345
		r = ReviewPack.new
		r.from_id(id)
		r.save

		size = r.size

    ds = Sequel.sqlite(DB_FILE)[:reviews]
    review = Review.new( :user => 'jg',
												 :date => Date.today,
												 :body => 'body',
												 :rating => 2,
												 :url => HOST + "/places/" + id,
												 :qtype_id => id)
		ds.insert(review.to_hash)


		# r.get_page("http://nonexistent.com.pl")
	end
end
