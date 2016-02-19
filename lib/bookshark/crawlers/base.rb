require File.expand_path(File.join(File.dirname(__FILE__), '../extractors', 'base'))

module Biblionet
  module Crawlers

    class Base
      def initialize(options = {})
        @folder             = options[:folder]            ||= 'lib/bookshark/storage/html_base_pages'
        @base_url           = options[:base_url]          ||= 'http://www.biblionet.gr/base/'
        @page_type          = options[:page_type]         ||= 'base'
        @extension          = options[:extension]         ||= '.html'
        @save_only_content  = options[:save_only_content] ||= false
        @start              = options[:start]             ||= 1
        @finish             = options[:finish]            ||= 10000
        @step               = options[:step]              ||= 1000
      end

      def spider
        start  = @start  + @step - 1
        finish = @finish
        
        start.step(finish, @step) do |last|  
          first     = last - @step + 1
          subfolder = (last/@step - 1).to_s          
          slash     = (@page_type != 'bg_record') ? '/' : ''
          path      = "#{@folder}/#{subfolder}/"

          # Create a new directory (does nothing if directory exists)
          # FileUtils.mkdir_p path

          first.upto(last) do |id|
            file_to_save    = "#{path}#{@page_type}_#{id}#{@extension}"
            url_to_download = "#{@base_url}#{id}#{slash}"

            yield(url_to_download, file_to_save)
            # downloader = Biblionet::Core::Base.new(url_to_download)
            # downloader.save_page(file_to_save) unless downloader.page.nil?

          end
        end
      end


    end


  end
end