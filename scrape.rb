require 'net/http'
require 'rubygems'
require 'uri'
require 'nokogiri'

exit 1 unless ARGV.length > 0

output_dir = './out'
Dir.mkdir output_dir unless File.exists? output_dir

ARGV.each do |domain|
	puts "Scraping #{domain}"
	Dir.mkdir "#{output_dir}/#{domain}" unless File.exists? "#{output_dir}/#{domain}"
	page = 1
	begin
		doc = Nokogiri::HTML(Net::HTTP.get(domain, "/page/#{page}"))
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
					response = Net::HTTP.get_response uri
					while response.kind_of? Net::HTTPRedirection
						uri = URI.parse response.header["Location"]
						response = Net::HTTP.get_response uri
					end
				rescue Error
				else
					outfile = "#{output_dir}/#{domain}/#{File.basename uri.path}"
					File.open(outfile, "w"){|f| f.write response.body } unless File.exists? outfile
				end
			end
		end
		threads.each{|t| t.join }
		puts
		page = page + 1
	end until doc.css("#content .pagination #next").length < 1
	puts
end
