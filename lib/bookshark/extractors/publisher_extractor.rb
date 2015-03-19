require_relative 'base'

module Biblionet
  module Extractors
    
    class PublisherExtractor < Base      
      attr_reader :publisher

      def initialize(uri=nil)
        super(uri)        
        extract_publisher unless uri.nil? or @page.nil?        
      end


      def load_and_extract_publisher(uri=nil)
        load_page(uri)
        extract_publisher unless uri.nil? or @page.nil?
      end    

      def extract_publisher(biblionet_id=@biblionet_id, publisher_page=@page)
        puts "Extracting publisher: #{biblionet_id}"
        page = PublisherDataExtractor.new(publisher_page)
        
        headquarters                    = page.headquarters
        bookstores                      = page.bookstores
        bookstores['Έδρα']              = headquarters 

        publisher_hash = {}
        publisher_hash['name']          = page.name
        publisher_hash['owner']         = page.owner       
        publisher_hash['bookstores']    = bookstores
        publisher_hash['b_id']          = biblionet_id

        return @publisher = publisher_hash
      end


    end

    class PublisherDataExtractor
      attr_reader :nodeset

      def initialize(document)
        # No need to operate on whole page. Just on part containing the content.
        content_re = /<!-- CONTENT START -->.*<!-- CONTENT END -->/m
        if (content_re.match(document)).nil?
          puts document
        end
        content = content_re.match(document)[0]

        @nodeset = Nokogiri::HTML(content)        
      end  

      def name
        @nodeset.css('h1.page_title').text.strip
      end

      def owner 
        return (@nodeset.xpath("//h1[@class='page_title'][1]/following::text()") & @nodeset.xpath("//table[@class='book_details'][1]/preceding::text()")).text.strip        
      end

      def headquarters
        headquarters_hash   = {}
        temp_array          = []
        current_key         = nil
        last_key            = nil

        @nodeset.xpath("//table[@class='book_details'][1]//tr").each do |item|
          key         = item.children[0].text.strip
          current_key = key.end_with?(":") ? key[0..-2] : last_key
          value       = item.children[1].text.strip

          unless key.empty? and value.empty?
            if current_key == last_key              
              temp_array << headquarters_hash[current_key] unless headquarters_hash[current_key].is_a?(Array)
              temp_array << value.gsub(/,$/, '').strip unless value.empty?
              headquarters_hash[current_key] = temp_array
            else
              temp_array                      = []
              headquarters_hash[current_key]  = value.gsub(/,$/, '').strip
            end
          end

          last_key = current_key          
        end

        # Change keys. Use the same as in bookstores.
        mappings                      = {"Διεύθυνση" => "address", "Τηλ" => "telephone", "FAX" => "fax", "E-mail" => "email", "Web site" => "website"}
        headquarters_hash             = Hash[headquarters_hash.map {|k, v| [mappings[k], v] }]
        headquarters_hash['website']  = headquarters_hash['website'].split(',').map(&:strip) if headquarters_hash['website'].include? ','

        return headquarters_hash                
      end

      def bookstores
        bookstores_hash = Hash.new { |h,k| h[k] = {} }
        address_array   = []
        tel_array       = []

        # Defaunt key in case there is none.
        key = 'Βιβλιοπωλείο'

        @nodeset.css('//p[align="justify"]').inner_html.split('<br>').map(&:strip).reject(&:empty?).each do |item|          
          regex_tel   = /\d{3} \d{7}/
          regex_tk    = /\d{3} \d{2}/
          regex_email = /([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+/i
          regex_url   = /((http(?:s)?\:\/\/)?[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)*\.[a-zA-Z]{2,6}(?:\/?|(?:\/[\w\-]+)*)(?:\/?|\/\w+\.[a-zA-Z]{2,4}(?:\?[\w]+\=[\w\-]+)?)?(?:\&[\w]+\=[\w\-]+)*)/ix
          
          if item.end_with?(":")                   
            key           = item[0..-2]
            address_array = []
            tel_array     = []
          elsif (item.start_with?("Fax") or item.start_with?("fax")) and item =~ regex_tel            
            bookstores_hash[key]['fax']        = item.gsub(/[^\d{3} \d{2}]/, '').strip            
          elsif item =~ regex_tel
            tel_array << item.gsub(/[^\d{3} \d{2}]/, '').strip            
            bookstores_hash[key]['telephone']  = tel_array            
          elsif item =~ regex_tk
            address_array << item.gsub(/,$/, '').strip                       
            bookstores_hash[key]['address']    = address_array            
          elsif item =~ regex_email            
            bookstores_hash[key]['email']      = (regex_email.match(item))[0]                        
          elsif item =~ regex_url            
            bookstores_hash[key]['website']    = item[regex_url,1]            
          else
            address_array << item.gsub(/,$/, '').strip            
            bookstores_hash[key]['address']    = address_array            
          end

        end

        return bookstores_hash
      end      

    end  

  end
end