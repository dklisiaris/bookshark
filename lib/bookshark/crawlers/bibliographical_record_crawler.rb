require_relative 'base'

module Biblionet
  module Crawlers

    class BibliographicalRecordCrawler < Base
      def initialize(options = {})
        options[:folder]            ||= 'lib/bookshark/storage/html_book_pages'
        options[:base_url]          ||= 'http://www.biblionet.gr/main.asp?page=results&Titlesid='
        options[:page_type]         ||= 'bg_record'
        options[:extension]         ||= '.html'
        options[:save_only_content] ||= true
        options[:start]             ||= 176001
        options[:finish]            ||= 180000
        options[:step]              ||= 1000    
        super(options)
      end

      def crawl_and_save 
        downloader = Extractors::Base.new

        spider do |url_to_download, file_to_save|                   
          downloader.load_page(url_to_download)

          # Create a new directory (does nothing if directory exists) 
          path = File.dirname(file_to_save)
          FileUtils.mkdir_p path unless File.directory?(path)
          
          # No need to download the whole page. Just the part containing the book.
          if @save_only_content
            content_re = /<!-- CONTENT START -->.*<!-- CONTENT END -->/m
            content    = content_re.match(downloader.page)[0] unless (content_re.match(downloader.page)).nil?
            downloader.save_to(file_to_save, content) unless downloader.page.nil? or downloader.page.length < 1024
          else
            downloader.save_page(file_to_save) unless downloader.page.nil? or downloader.page.length < 1024
          end
                    
        end
      end
    end

  end
end