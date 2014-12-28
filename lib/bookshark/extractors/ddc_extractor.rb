require 'rubygems'
require 'nokogiri'

require_relative 'base'

module Biblionet
  module Extractors

    class DDCExtractor < Base
      attr_reader :ddcs

      def initialize(uri=nil)
        super(uri)        
        extract_ddcs unless uri.nil?        
      end

      def extract_ddcs(ddc_page=@page)
        page = Nokogiri::HTML(ddc_page)  
        parent, previous_indent, previous_id = nil, nil, nil,

        @ddcs = page.xpath("//a[@class='menu' and @href[contains(.,'/index/') ]]").map do |ddc|      
          # Extract from href the id used by biblionet. --- DdC url http://biblionet.gr/index/id ---
          biblionet_id = ddc['href'].split(/\//).last

          # Get the text before <a>. It is expected to be a number of space characters
          spaces = ddc.previous_sibling.text # TODO: make sure text is only spaces           
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
          ddc = proccess_ddc(ddc.text)

          ddc.merge!(parent: parent)
          
          ddc_hash = {biblionet_id => ddc.clone}
        end.reduce({}, :update) unless @page.nil? 
        
        return @ddcs  
      end

      def extract_ddcs_from(uri=nil)
        load_page(uri)
        extract_ddcs unless uri.nil?
      end


      private

      def proccess_ddc(ddc)
        # matches the digits inside [] in text like: [889.09300] Νεοελληνική λογοτεχνία - Ιστορία και κριτική (300)  
        id_re = /(\[\d*(?:[\.|\s]\d*)*\])/

        # matches [digits] and (digits) in text like: [889.09300] Νεοελληνική λογοτεχνία - Ιστορία και κριτική (300)   
        non_text_re = /\s*(\[.*\]|\(\d*\))\s*/
        
        ddc_id = ddc.scan(id_re).join.gsub(/[\[\]]/, '')
        ddc_text = ddc.gsub(non_text_re, '').strip

        ddc_hash = { ddc: ddc_id, text: ddc_text } 
        return ddc_hash
      end

    end

  end
end

# ddcp = DDCParser.new("raw_ddc_pages/0/ddc_787.html")
# ddcp.extract_ddcs

# ddcp.filepath="ddc_1.html"