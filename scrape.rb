#!/usr/bin/env ruby

require 'net/http'
require 'rubygems'
require 'uri'
require 'nokogiri'

exit 1 unless ARGV.length > 0

output_dir = './out'
Dir.mkdir output_dir unless File.exists? output_dir

ARGV.each do |domain|

	outfile = lambda do |uri|
		"#{output_dir}/#{domain}/#{File.basename uri.path}"
	end
	get_response = lambda do |uri|
		Thread.exit if File.exists? outfile.call uri
		Net::HTTP.get_response uri
	end

	puts "Scraping #{domain}"
	Dir.mkdir outfile.call(URI.parse ".") unless File.exists? outfile.call(URI.parse ".")

	page = 1
	doc = Nokogiri::HTML(Net::HTTP.get(domain, "/"))
	until doc.css("#content .pagination #next").length < 1
		doc = Nokogiri::HTML(Net::HTTP.get(domain, "/page/#{page}")) unless page == 1
		current_page = doc.css("#content .pagination .total")[0].content

		print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
		print "Scraping page #{current_page} ..."
		$stdout.flush

		threads = []
		doc.css("#content .post .post-photo a").each do |anchor|
			href = anchor.attr "href"
			threads << Thread.new(href) do
				begin
					uri = URI.parse href
					response = get_response.call uri
					while response.kind_of? Net::HTTPRedirection
						uri = URI.parse response.header["Location"]
						response = get_response.call uri
					end
				rescue Exception => e
					puts e.inspect
				else
					File.open(outfile.call(uri), "w"){|f| f.write response.body }
				end
			end
		end
		threads.each{|t| t.join }

		page = page + 1
	end

	puts
end
