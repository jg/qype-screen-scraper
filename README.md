Preparing environment 
------------

		rvm use 1.9.2
		gem install nokogiri

Running migrations 
---------

		make db
	
Usage
---------

		ruby main.rb [URL|QTYPE_ID]

Examples
---------

		ruby main.rb http://www.qype.com/place/13080-Bar-Gagarin-Berlin
		ruby main.rb 13080

