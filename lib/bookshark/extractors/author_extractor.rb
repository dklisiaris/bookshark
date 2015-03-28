#!/bin/env ruby
# encoding: utf-8

require_relative 'base'

module Biblionet
  module Extractors
    
    class AuthorExtractor < Base      
      attr_reader :author

      def initialize(uri=nil)
        super(uri)        
        extract_author unless uri.nil? or @page.nil?        
      end


      def load_and_extract_author(uri=nil)
        load_page(uri)
        extract_author unless uri.nil? or @page.nil?
      end   

      # def to_json_pretty
      #    JSON.pretty_generate(@author) unless @author.nil?
      # end  

      def extract_author(biblionet_id=@biblionet_id, author_page=@page)
        puts "Extracting author: #{biblionet_id}"
        page = AuthorDataExtractor.new(author_page)
        
        identity = split_name(page.fullname)

        author_hash = {}
        if present?(identity[:lastname]) and present?(identity[:firstname]) 
          author_hash[:name] = identity[:lastname] + ', ' + identity[:firstname] 
        elsif 
          author_hash[:name] = identity[:lastname]
        end      
        author_hash[:firstname] = identity[:firstname]
        author_hash[:lastname] = identity[:lastname]
        author_hash[:extra_info] = identity[:extra_info]
        author_hash[:image] = page.image
        author_hash[:bio] = page.bio
        author_hash[:award] = page.awards
        author_hash[:b_id] = biblionet_id

        # puts JSON.pretty_generate(author_hash)

        if author_hash[:lastname].nil? and author_hash[:firstname].nil?
          return nil
        else
          return @author = author_hash
        end

      end

      def split_name(fullname)
        #mathes digits-digits or digits- in text like: Tolkien, John Ronald Reuel, 1892-1973
        years_re = /\d+-\d*/

        parts = fullname.split(',').map(&:strip)  

        identity = {}
        identity[:lastname] = parts[0]
        
        if parts.length == 2
          if parts[1] =~ years_re
            identity[:extra_info] = parts[1]
          else
            identity[:firstname] = parts[1]
          end
        elsif parts.length == 3
          identity[:firstname] = parts[1]
          identity[:extra_info] = parts[2]
        end

        return identity
      
      end

    end

    class AuthorDataExtractor
      attr_reader :nodeset

      def initialize(document)
        # No need to operate on whole page. Just on part containing the content.
        content_re = /<!-- CONTENT START -->.*<!-- CONTENT END -->/m
        if (content_re.match(document)).nil?
          puts document
        end
        content = content_re.match(document)[0] unless (content_re.match(document)).nil?

        @nodeset = Nokogiri::HTML(content)        
      end  

      def fullname
        @nodeset.css('h1.page_title').text
      end

      def bio
        @nodeset.css('//p[align="justify"]').text
      end

      def image
        img_node  = @nodeset.xpath("//img[@src[contains(.,'/persons/')]][1]")                                                   
        img       = (img_node.nil? or img_node.empty?) ? nil : BASE_URL+(img_node.first)['src']                             
        return img         
      end

      def awards
        awards = []        
        @nodeset.xpath("//a[@class='booklink' and @href[contains(.,'page=showaward') ]]").each do |item|
          award = {name: item.text, year: item.next_sibling.text.strip.gsub(/[^\d]/, '')}          
          awards << award
        end

        return awards
      end

    end  

  end
end