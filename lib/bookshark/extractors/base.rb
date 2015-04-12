#!/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'open-uri'
require 'fileutils'
require 'nokogiri'
require 'json'
require 'logger'
require 'pp'
require 'htmlentities'

require File.expand_path(File.join(File.dirname(__FILE__), '../storage', 'file_manager'))

module Biblionet
  module Extractors
    
    BASE_URL ||= "http://www.biblionet.gr"

    class Base
      include FileManager

      attr_reader :filepath, :url, :biblionet_id, :page

      # Initializes the Base class. Without arguments nothing happens. Otherwise loads a page by url or file.
      #
      # ==== Attributes
      #
      # * +uri+ - It can be a url or a path/to/file.ext on local storage.
      # 
      def initialize(uri=nil)          
        load_page(uri)
      end

      # Loads a page from the web or from local file storage depending on passed argument.
      #
      # ==== Attributes
      #
      # * +uri+ - It can be a url(starting with http/https) or a path/to/file.ext on local storage.
      # 
      def load_page(uri=nil)      
        if uri.match(/\A#{URI::regexp(['http', 'https'])}\z/)        
          load_page_from_url(uri)
        else                
          load_page_from_file(uri)
        end unless uri.nil?
      end

      # Downloads a page from the web.
      #
      # ==== Attributes
      #
      # * +url+ - The url of webpage to download.
      # 
      def load_page_from_url(url)
        begin
          @url = url
          @biblionet_id = url[/\d+(?!.*\d+)/] unless url.nil? # id is expected to be the last number.

          pp "Downloading page: #{url}"
          open(url, :content_length_proc => lambda do |content_length|
            raise EmptyPageError.new(url, content_length) unless content_length.nil? or content_length > 1024
          end) do |f|        
            # pp f.status == ["200", "OK"] ? "success: #{f.status}" : f.status            
            # pp  f.meta
            # pp "Content-Type: " + f.content_type
            # pp "Content-Size: " + (f.meta)["content-length"]
            # pp "last modified" + f.last_modified.to_s + is_empty = (f.last_modified.nil?) ? 'Empty' : 'Not Empty' 

            @page = f.read.gsub(/\s+/, " ")
          end
        rescue Errno::ENOENT => e
          pp "Page: #{url} NOT FOUND."
          pp e
        rescue EmptyPageError => e
          pp "Page: #{url} is EMPTY."
          pp e        
          @page = nil
        rescue OpenURI::HTTPError => e
          pp e
          pp e.io.status          
        rescue StandardError => e          
          pp "Generic error #{e.class}. Will wait for 2 minutes and then try again."
          pp e        
          sleep(120)
          retry        
        end
      end

      # Reads a page from the local file system.
      #
      # ==== Attributes
      #
      # * +filepath+ - The path to target file which will be read.
      # 
      def load_page_from_file(filepath)    
        begin        
          @filepath = filepath
          @biblionet_id = filepath[/\d+(?!.*\d+)/] unless filepath.nil?
          @page = open(filepath).read  
        rescue StandardError => e
          puts e
        end     
      end

      # Attr writer method. Changes instance variables url, page and loads a new page by calling load_page_from_url
      #
      # ==== Attributes
      #
      # * +url+ - The new value of url instance var.
      # 
      def url=(url)
        load_page_from_url(url)
      end 

      # Attr writer method. Changes instance variables filepath, page and loads a new page by calling load_page_from_filename
      #
      # ==== Attributes
      #
      # * +filepath+ - The path to target file which will be read.
      # 
      def filepath=(filepath)
        load_page_from_file(filepath)
      end  

      # Saves page to file.
      #
      # ==== Attributes
      #
      # * +path+ - The path to file(including filename) where content will be saved.
      #
      def save_page(path)
        save_to(path, @page)
        pp "Saving page: #{path}"
      end

      # Decodes text with escaped html entities and returns the decoded text.
      #
      # ==== Params:
      #
      # +encoded_text+:: the text which contains encoded entities
      #
      def decode_text(encoded_text)
        # encoded_text = File.read(encoded_file_path)
        coder = HTMLEntities.new
        coder.decode(encoded_text)
      end

      def present?(value)
        return (not value.nil? and not value.empty?) ? true : false
      end        

    end

    # Raised when a page is considered empty.
    #
    class EmptyPageError < StandardError
      attr_reader :url, :content_length

      def initialize(url, content_length)
        @url = url
        @content_length = content_length

        msg = "Page: #{url} is only #{content_length} bytes, so it is considered EMPTY."
        super(msg)
      end    
    end

    # Raised when something unexpected or in wrong format is parsed.
    #
    class NoIdeaWhatThisIsError < StandardError      
      attr_reader :biblionet_id, :the_unexpected

      def initialize(biblionet_id, the_unexpected)
        @biblionet_id = biblionet_id
        @the_unexpected = the_unexpected
        
        msg = "We have no idea what this: #{the_unexpected} is. At book #{biblionet_id}"
        super(msg)
      end    
    end    

  end
end

# page = Parser::ParserBase.parse("http://www.biblionet.gr/book/300525")
# pp page.inspect
# Parser::ParserBase.parse("http://www.biblionet.gr/book/195243421")
# Parser::ParserBase.parse("dsdfds.com")
# Parser::ParserBase.save_to("book_195221.html", page)
