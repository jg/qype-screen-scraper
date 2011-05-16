test:
	ruby test.rb
db:
	rm reviews.db; sequel -m migrations/ sqlite://reviews.db

