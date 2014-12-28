require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'fileutils'

require File.expand_path(File.join(File.dirname(__FILE__), '../extractors', 'base'))

DEFAULTS = {
  folder: 'storage/html_author_pages',
  base_url: 'http://www.biblionet.gr/author/',
  extension: '.html',
  first_id: 1,
  last_id: 112000,
  step: 1000
}

def crawl_and_save(options={})
  options = DEFAULTS.merge(options)

  start_id  = options[:first_id] + options[:step] - 1
  last_id   = options[:last_id]
  step      = options[:step]

  start_id.step(last_id, step) do |last|  
    first     = last - step + 1
    subfolder = (last/step - 1).to_s
    path      = "#{options[:folder]}/#{subfolder}/"

    # Create a new directory (does nothing if directory exists)
    FileUtils.mkdir_p path

    first.upto(last) do |id|
      file_to_save = "#{path}author_#{id}#{options[:extension]}"
      url_to_download = "#{options[:base_url]}#{id}/"

      downloader = Biblionet::Core::Base.new(url_to_download)
      downloader.save_page(file_to_save) unless downloader.page.nil?

    end
  end

end

crawl_and_save