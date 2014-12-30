require_relative 'base'

module Biblionet
  module Crawlers

    class PublisherCrawler < Base
      def initialize(options = {})
        options[:folder]    ||= 'lib/bookshark/storage/html_publisher_pages'
        options[:base_url]  ||= 'http://www.biblionet.gr/com/'
        options[:page_type] ||= 'publisher'
        options[:extension] ||= '.html'
        options[:start]     ||= 1
        options[:finish]    ||= 800
        options[:step]      ||= 100        
        super(options)
      end

      def crawl_and_save 
        downloader = Extractors::Base.new

        spider do |url_to_download, file_to_save|                   
          downloader.load_page(url_to_download)

          # Create a new directory (does nothing if directory exists) 
          path = File.dirname(file_to_save)
          FileUtils.mkdir_p path unless File.directory?(path)

          downloader.save_page(file_to_save) unless downloader.page.nil? or downloader.page.length < 1024

        end
      end
    end

  end
end