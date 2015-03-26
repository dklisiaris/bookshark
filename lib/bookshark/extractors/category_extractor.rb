#!/bin/env ruby
# encoding: utf-8

require_relative 'base'

module Biblionet
  module Extractors

    class CategoryExtractor < Base
      attr_reader :categories

      def initialize(uri=nil)
        super(uri)        
        extract_categories unless uri.nil? or @page.nil?         
      end

      def extract_categories(category_page=@page)
        page = Nokogiri::HTML(category_page)  
        parent, previous_indent, previous_id = nil, nil, nil,

        @categories = page.xpath("//a[@class='menu' and @href[contains(.,'/index/') ]]").map do |category|      
          # Extract from href the id used by biblionet. --- DdC url http://biblionet.gr/index/id ---
          biblionet_id = category[:href].split(/\//).last

          # Get the text before <a>. It is expected to be a number of space characters
          spaces = category.previous_sibling.text # TODO: make sure text is only spaces           
          # Indent size
          indent = spaces.size

          # Determine parent-child-sibling relationships based on indent.
          # Indent size seems to be inconsistent, so it better to compare sizes than actually use them.
          if (indent <=> previous_indent).nil?
            previous_indent = indent
          elsif (indent <=> previous_indent)>0
            parent = previous_id
            previous_indent = indent        
          end

          previous_id = biblionet_id

          # Extact DdC id and DdC text.     
          category = proccess_category(category.text)

          category.merge!(parent: parent)
          
          category_hash = {biblionet_id => category.clone}
        end.reduce({}, :update) unless @page.nil?               

        if present?(@categories)
          @categories[:current] = (@categories[@biblionet_id.to_s].clone)
          @categories[:current][:b_id] = @biblionet_id
          return @categories
        else
          return nil
        end                
      end

      def extract_categories_from(uri=nil)
        load_page(uri)
        extract_categories unless uri.nil? or @page.nil? 
      end


      private

      def proccess_category(category)
        # matches the digits inside [] in text like: [889.09300] Νεοελληνική λογοτεχνία - Ιστορία και κριτική (300)  
        ddc_re = /(\[\d*(?:[\.|\s]\d*)*\])/

        # matches [digits] and (digits) in text like: [889.09300] Νεοελληνική λογοτεχνία - Ιστορία και κριτική (300)   
        non_text_re = /\s*(\[.*\]|\(\d*\))\s*/
        
        category_ddc = category.scan(ddc_re).join.gsub(/[\[\]]/, '')
        category_name = category.gsub(non_text_re, '').strip

        category_hash = { ddc: category_ddc, name: category_name } 
        return category_hash
      end

    end

  end
end

# categoryp = DDCParser.new("raw_category_pages/0/category_787.html")
# categoryp.extract_categories

# categoryp.filepath="category_1.html"