require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'

require File.expand_path(File.join(File.dirname(__FILE__), '../extractors', 'base'))
# page = Nokogiri::HTML(open("raw_html_pages/book_45454.html"))   
# puts page.class   # => Nokogiri::HTML::Document
# puts page

FOLDER = 'html_dcc_pages'
BASE_URL = 'http://www.biblionet.gr/index/'
EXTENSION = '.html'

1000.step(6000, 1000) do |last|  
  # saved_pages = 0
  # empty_pages = 0

  first = last - 1000 + 1
  subfolder = (last/1000 - 1).to_s
  path = "#{FOLDER}/#{subfolder}/"

  # Create a new directory (does nothing if directory exists)
  FileUtils.mkdir_p path

  first.upto(last) do |id|
    file_to_save = "#{path}dcc_#{id}#{EXTENSION}"
    url_to_download = "#{BASE_URL}#{id}/"

    downloader = Biblionet::Core::Base.new(url_to_download)
    downloader.save_page(file_to_save) unless downloader.page.nil? 

    # open(url_to_parse) do |uri|
    #   puts "Parsing page: #{url_to_parse}"
    #   page = uri.read.gsub(/\s+/, " ")
    #   # doc = Nokogiri::HTML(page)
    #   # body = doc.at('title').inner_html
    #   # puts body
    #   if page.include? "</body>"
    #     puts "Saving page: #{file_to_save}"
    #     open(file_to_save, "w") do |file|
    #       file.write(page)
    #     end        
    #     saved_pages += 1
    #   else
    #     puts "Page #{file_to_save} seems to be empty..."
    #     empty_pages += 1
    #   end
    # end
  end

  # puts "Saved Pages: #{saved_pages}"
  # puts "Empty Pages: #{empty_pages}"

end
