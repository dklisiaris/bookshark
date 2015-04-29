#!/bin/env ruby
# encoding: utf-8

require_relative 'base'


module Biblionet
  module Extractors   
    
    class BibliographicalBookExtractor < Base 
      attr_reader :bibliographical_book

      def initialize(uri=nil)
        super(uri)        
        extract_bibliographical_book unless uri.nil? or @page.nil?        
      end

      def load_and_extract_book(uri=nil)
        load_page(uri)
        extract_bibliographical_book unless uri.nil? or @page.nil?
      end  

      def extract_bibliographical_book(biblionet_id=@biblionet_id, book_page=@page)                
        # log = Logger.new(File.new(File.dirname(__dir__).to_s + "/logs/book_parsing.log",'a+'))
        log = Logger.new(STDOUT)
                       
        page = BibliographicalBookDataExtractor.new(book_page)

        # End extraction if BookDataExtractor couldnt create a nodeset
        return nil if page.nodeset.nil?

        bibliographical_book_hash = Hash.new   

        extracted_details = page.details

        bibliographical_book_hash[:original_language] = extracted_details[:original_language]
        bibliographical_book_hash[:original_title]    = extracted_details[:original_title]
        bibliographical_book_hash[:last_update]       = extracted_details[:last_update]
        bibliographical_book_hash[:cover_type]        = extracted_details[:cover_type]
        bibliographical_book_hash[:availability]      = extracted_details[:availability]
        bibliographical_book_hash[:price]             = extracted_details[:price]

        bibliographical_book_hash[:series]            = extracted_details[:series]
        bibliographical_book_hash[:physical_size]     = extracted_details[:physical_size]

        bibliographical_book_hash[:format]            = extracted_details[:format]

        bibliographical_book_hash[:publisher]         = extracted_details[:publisher]
        bibliographical_book_hash[:publication]       = extracted_details[:publication]
        
        return @bibliographical_book = bibliographical_book_hash
      end

    end

    class BibliographicalBookDataExtractor
      attr_reader :nodeset

      def initialize(document)
        # No need to operate on whole page. Just on part containing the book.
        content_re = /<!-- CONTENT START -->.*<!-- CONTENT END -->/m
        if (content_re.match(document)).nil?
          puts document
        end
        content = content_re.match(document)[0] unless (content_re.match(document)).nil?
        
        # If content is nil, there is something wrong with the html, so return nil
        if content.nil?
          @nodeset = nil
        else
          @nodeset = Nokogiri::HTML(content) 
        end        
      end    

      def size
        size_regex = /\d+x\d+/
      end

      def series
        series_regex        = /(?<=\()\p{Word}+( \p{Word}+)* · \d+(?=\))/
        series_name_regex   = /\p{Word}+( \p{Word}+)*(?= ·)/
        series_volume_regex = /(?<=· )\d+/
      end

      def details
        details_hash        = {}
        isbn_regex          = /(?<= )\d+-\d+-\d+-\d+(?= |,)/
        isbn_13_regex       = /\d+-\d+-\d+-\d+-\d+/
        last_update_regex   = /\d{1,2}\/\d{1,2}\/\d{2,4}/
        cover_type_regex    = /(?<=\()\p{Word}+( \p{Word}+)?(?=\))/
        availability_regex  = /(?<=\[).+(?=\])/
        price_regex         = /(?<=€ )\d+,\d*/

        @nodeset.xpath("//span[@class='small'][1]").inner_html.split('<br>').each do |detail|
          detail = BibliographicalBookExtractor.decode_text(detail)

          if detail.start_with? "Γλώσσα πρωτοτύπου:"
            original_language = detail.gsub(/Γλώσσα πρωτοτύπου:/, "").strip
            details_hash[:original_language] = original_language
          elsif detail.start_with? "Τίτλος πρωτοτύπου:"
            original_title = detail.gsub(/Τίτλος πρωτοτύπου:/, "").strip
            details_hash[:original_title] = original_title
          end
          
          details_hash[:isbn]         = detail[isbn_regex] if detail =~ isbn_regex                 

          details_hash[:isbn_13]      = detail[isbn_13_regex] if detail =~ isbn_13_regex

          details_hash[:last_update]  = detail[last_update_regex] if detail =~ last_update_regex 

          details_hash[:cover_type]   = detail[cover_type_regex] if detail =~ cover_type_regex  

          details_hash[:availability] = detail[availability_regex] if detail =~ availability_regex

          details_hash[:price]        = detail[price_regex] if detail =~ price_regex 
          
        end

        pre_details_text = @nodeset.xpath("//span[@class='small'][1]/preceding::text()").text
        pre_details_text = BibliographicalBookExtractor.decode_text(pre_details_text)

        series_regex        = /(?<=\()\p{Word}+( \S)?( \p{Word}+( \S)?)* · \d+(?=\))/
        series_regex_no_vol = /(?<=\()\p{Word}+( \S)?( \p{Word}+( \S)?)*(?=\))/
        series_name_regex   = /\p{Word}+( \S)?( \p{Word}+( \S)?)*(?= ·)/
        series_volume_regex = /(?<=· )\d+/
        physical_size_regex = /\d+x\d+/        

        series_hash = {}
        if pre_details_text =~ series_regex
          series = pre_details_text[series_regex]
          series_hash[:name]    = series[series_name_regex] if series =~ series_name_regex
          series_hash[:volume]  = series[series_volume_regex] if series =~ series_volume_regex          
        elsif pre_details_text =~ series_regex_no_vol
          series = pre_details_text[series_regex_no_vol]
          series_hash[:name]    = series
          series_hash[:volume]  = nil
        end

        details_hash[:series] = series_hash
        
        details_hash[:physical_size] = (pre_details_text =~ physical_size_regex) ? pre_details_text[physical_size_regex] : nil

        format_regex = /(?<=\[).+(?=\])/

        after_title_text = @nodeset.xpath("//a[@class='booklink' and @href[contains(.,'/book/') ]][1]").first.next_sibling.text.strip
        format = after_title_text[format_regex] if after_title_text =~ format_regex

        details_hash[:format] = format.nil? ? 'Βιβλίο' : format

        publisher_node = @nodeset.xpath("//a[@class='booklink' and @href[contains(.,'/com/') ]][1]").first
        publisher_hash = {}
        publisher_hash[:text] = publisher_node.text
        publisher_hash[:b_id] = (publisher_node[:href].split("/"))[2]

        pre_publisher_text = BibliographicalBookExtractor.decode_text(publisher_node.previous_sibling.text)
        after_publisher_text = BibliographicalBookExtractor.decode_text(publisher_node.next_sibling.text)

        publication_hash = {}
        publication_hash[:year] = after_publisher_text[/(?<=, )\d+(?=\.)/]
        publication_hash[:version] = pre_details_text[/(?<=- )\d+(?=η)/]
        publication_hash[:place] = pre_details_text[/(?<=- )\p{Word}+( \S)?( \p{Word}+( \S)?)*(?= :)/]

        details_hash[:publisher] = publisher_hash
        details_hash[:publication] = publication_hash

        details_hash
      end

    end

  end
end