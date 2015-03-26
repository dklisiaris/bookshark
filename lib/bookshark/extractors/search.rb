#!/bin/env ruby
# encoding: utf-8

require_relative 'book_extractor'

module Biblionet
  module Extractors

    class Search < BookExtractor
      def initialize(options = {})
        perform_search(options) unless options.empty?
      end  

      def perform_search(options = {})
        search_url = build_search_url(options)
        load_page(URI.encode(search_url)) # Page gets loaded on @page variable.

        book_ids = []

        # No need to operate on whole page. Just on part containing the book.
        content_re = /<!-- CONTENT START -->.*<!-- CONTENT END -->/m
        if (content_re.match(@page)).nil?
          puts @page
        end
        content = content_re.match(@page)[0]

        nodeset = Nokogiri::HTML(content)                   
        nodeset.xpath("//a[@class='booklink' and @href[contains(.,'/book/') ]]").each do |item|
          book_ids << item[:href].split("/")[2] 
        end

        books = []

        if options[:results_type] == 'ids'
          return book_ids          
        elsif options[:results_type] == 'metadata'          
          book_ids.each do |id|
            url = "http://www.biblionet.gr/book/#{id}"
            books << load_and_extract_book(url)
          end                            
        end

        return books    
      end

      def search_by_isbn(isbn)
        results = perform_search(isbn: isbn, results_type: 'ids')
        book_id = results.empty? ? nil : results.first.to_i
      end

      def build_search_url(options = {})
        title         = present?(options[:title])     ? options[:title].gsub(' ','+')     : ''
        author        = present?(options[:author])    ? options[:author].gsub(' ','+')    : ''
        publisher     = present?(options[:publisher]) ? options[:publisher].gsub(' ','+') : ''
        category      = present?(options[:category])  ? options[:category].gsub(' ','+')  : ''

        title_split   = options[:title_split]  ||= '1'
        book_id       = options[:book_id]      ||= ''
        isbn          = options[:isbn]         ||= ''        
        author_id     = options[:author_id]    ||= ''        
        publisher_id  = options[:publisher_id] ||= ''      
        category_id   = options[:category_id]  ||= ''
        after_year    = options[:after_year]   ||= ''
        before_year   = options[:before_year]  ||= ''

        url_builder = StringBuilder.new
        url_builder.append('http://www.biblionet.gr/main.asp?page=results')
        url_builder.append('&title=')
        url_builder.append(title)
        url_builder.append('&TitleSplit=')
        url_builder.append(title_split)
        url_builder.append('&Titlesid=')
        url_builder.append(book_id)
        url_builder.append('&isbn=')
        url_builder.append(isbn)
        url_builder.append('&person=')
        url_builder.append(author)
        url_builder.append('&person_ID=')
        url_builder.append(author_id)
        url_builder.append('&com=')
        url_builder.append(publisher)
        url_builder.append('&com_ID=')
        url_builder.append(publisher_id)
        url_builder.append('&from=')
        url_builder.append(after_year)        
        url_builder.append('&untill=')
        url_builder.append(before_year)
        url_builder.append('&subject=')
        url_builder.append(category)
        url_builder.append('&subject_ID=')
        url_builder.append(category_id)
        url_builder.build
      end        

    end

    class StringBuilder      
      def initialize
        @string = []        
      end

      def append(text)
        @string << text
      end

      def build
        @string.join.to_s
      end
    end

  end
end
