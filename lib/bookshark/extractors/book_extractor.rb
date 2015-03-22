require_relative 'base'
require 'sanitize'

module Biblionet
  module Extractors   
    
    class BookExtractor < Base      
      attr_reader :book

      def initialize(uri=nil)
        super(uri)        
        extract_book unless uri.nil?        
      end

      def load_and_extract_book(uri=nil)
        load_page(uri)
        extract_book unless uri.nil?
      end      

      # Converts the parsed contributors string to hash. 
      # String must have been processed into the following form:
      # job1: contributor1, contributor2 job2: contributor3
      # The returned hash is in form: {job1 => ["contributor1","contributor2"],job2 => ["contributor3"]}
      def proccess_contributors(raw_contributors)
        contributors  = Hash.new
        partners      = Array.new
        job           = :author
        raw_contributors.each do |cb|
          if cb.is_a?(String) and cb.end_with? ":"
            job = cb[0..-2]
            partners.clear
          else
            partners << cb
            contributors[job] =  partners.clone
          end  
        end unless raw_contributors.nil? or raw_contributors.empty?
        
        return contributors
      end

      def proccess_details(details)
        details_hash = Hash.new
        
        details.each do |detail|          
          date_regex = /(^\d{4}$)/
          status_regex = /^\[\p{Word}+(?:\s*[\'\-\+\s]\s*\p{Word}+)*\]$/  
          detail = decode_text(detail)

          begin
            if detail =~ date_regex
              #puts "Publication Year: #{detail}"
              details_hash[:publication_year] = detail
            elsif detail.end_with? "σελ."
              pages = detail.gsub(/[^\d]/, '')
              #puts "Pages: #{pages}"
              details_hash[:pages] = pages
            elsif detail.start_with? "ISBN-13"
              isbn_13 = detail.gsub(/ISBN-13 /, "")
              details_hash[:isbn_13] = isbn_13
              #puts "ISBN: #{isbn_13}"      
            elsif detail.start_with? "ISBN"
              isbn = detail.gsub(/ISBN /, "")
              #puts "ISBN: #{isbn}"
              details_hash[:isbn] = isbn
            elsif detail =~ status_regex
              status = detail.gsub(/\[|\]/, '')
              #puts "Status: #{status}"
              details_hash[:status] = status
            elsif detail.start_with? "Τιμή"
              price = detail.gsub(/[^\d,\d]/, '')
              #puts "Price: #{price}"
              details_hash[:price] = price
            elsif detail.start_with? '<img src="/images/award.jpg" border="0" title="Βραβείο">'
              award = Sanitize.clean(detail).strip
              details_hash[:awards] = [] if details_hash[:awards].nil?
              details_hash[:awards] << award
            elsif detail.start_with? "ISMN" #Special typo case
              isbn = detail.gsub(/ISMN /, "")
              #puts "ISBN: #{isbn}"
              details_hash[:isbn] = isbn              
            else 
              raise NoIdeaWhatThisIsError.new(@biblionet_id, detail)
            end
          rescue NoIdeaWhatThisIsError => e
            pp e        
          end
        end

        return details_hash
      end

      def proccess_ddc(ddc, extract_parents = false)
        # Matches only the digits inside [] in text like: [889.09300] Νεοελληνική λογοτεχνία - Ιστορία και κριτική (300)  
        id_re = /(\[DDC\:\s\d*(?:[\.|\s]\d*)*\])/

        # Matches [digits] and (digits) in text like: [889.09300] Νεοελληνική λογοτεχνία - Ιστορία και κριτική (300)   
        non_text_re = /\s*(\[.*\]|\(.*\))\s*/
                
        # Gets the dcc part from text and removes anything but digits in [DDC: digits].                
        ddc_id = ddc.scan(id_re).join.gsub(/[\[\]DDC: ]/, '') # Gets the dcc part from text. 

        # Extracts the parent tree of current ddc.
        # ddcparser.parse(ddc_id)       

        # Gets text by reomoving anything but text.
        ddc_text = ddc.gsub(non_text_re, '').strip

        ddc_hash = { ddc: ddc_id, name: ddc_text } 
        return ddc_hash
      end  


      def extract_book(biblionet_id=@biblionet_id, book_page=@page)                
        log = Logger.new(File.new(File.dirname(__dir__).to_s + "/logs/book_parsing.log",'a+'))
                
        page = BookDataExtractor.new(book_page)

        book_hash = Hash.new      

        begin                
          img = page.image                            
          raise NoImageError.new(biblionet_id) if img.nil?
        rescue NoImageError => e
          pp e 
          log.warn(e.message)                
        rescue StandardError => e
          pp err_msg = "Error #{e} at book: #{biblionet_id}" 
          log.error(err_msg)                            
        end

        book_hash[:title] = page.title 
        book_hash[:subtitle] = page.subtitle        
        book_hash[:image] = img                          
      
        contributors = proccess_contributors(page.contributors)

        author = contributors[:author]
        contributors.delete(:author)
        
        # If author is empty, maybe its a collective work.
        if author.nil? #or author.empty?
          if page.collective_work?     
            # author = 'Συλλογικό έργο'
            author = ['Συλλογικό έργο']
          else
            # author = nil
            pp err_msg = "No author has been found at book: #{biblionet_id}" 
            log.error(err_msg)             
          end
        end

        book_hash[:author]       = author
        book_hash[:contributors] = contributors        
        book_hash[:publisher]    = page.publisher

        details = page.details
        if details.nil?
          pp err_msg = "No details at book: #{biblionet_id}"
          log.error(err_msg)       
        end        

        details_hash = proccess_details(details)

        book_hash[:publication_year] = details_hash[:publication_year]
        book_hash[:pages]            = details_hash[:pages]
        book_hash[:isbn]             = details_hash[:isbn]
        book_hash[:isbn_13]          = details_hash[:isbn_13].nil? ? nil : details_hash[:isbn_13]
        book_hash[:status]           = details_hash[:status]
        book_hash[:price]            = details_hash[:price]
        book_hash[:award]            = page.awards


        book_hash[:description] = page.description

        ddcs = page.ddcs.map do |ddc|      
                # Extract from href the ddc id used by biblionet. --- DdC url http://biblionet.gr/index/id ---
                ddc_biblionet_id = ddc[:href].split(/\//).last
                # Extact DdC id and DdC text.     
                ddc = proccess_ddc(ddc.text)

                ddc.merge!(b_id: ddc_biblionet_id)

              end


        book_hash[:category]   = ddcs
        book_hash[:b_id] = biblionet_id 

        return @book = book_hash  
      end      
    end

    class BookDataExtractor
      attr_reader :nodeset

      def initialize(document)
        # No need to operate on whole page. Just on part containing the book.
        content_re = /<!-- CONTENT START -->.*<!-- CONTENT END -->/m
        if (content_re.match(document)).nil?
          puts document
        end
        content = content_re.match(document)[0]

        @nodeset = Nokogiri::HTML(content)        
      end

      def image
        img_node = nil
        img_nodes = @nodeset.xpath("/html/body//img").each do |i|
          img_candidate = i.xpath("//img[@src[contains(.,'/covers/')]][1]") 
          img_node = img_candidate unless img_candidate.nil? or img_candidate.empty?                        
        end                    

        img = img_node.nil? ? nil : BASE_URL+(img_node.first)[:src]                             

        return img 
      end

      def title
        @nodeset.css('h1.book_title').text
      end

      def subtitle
        subtitle = nil
        @nodeset.xpath("//h1[@class='book_title']").each do |item|
          if item.next_element.name == 'br' and item.next_element.next.name != 'br'
            subtitle = item.next_element.next.text.strip
          end
        end
        subtitle
      end

      def publisher
        publisher_hash = {}
        @nodeset.xpath("//a[@class='booklink' and @href[contains(.,'/com/') ]]").each do |item| 
          publisher_hash[:name] = item.text
          publisher_hash[:b_id] = (item[:href].split("/"))[2]
        end
        publisher_hash
      end

      def contributors
        contributors = []
        @nodeset.xpath("//a[@class='booklink' and @href[contains(.,'/author/') ]]").each do |item| 
          pre_text = item.previous.text.strip           
          contributors << pre_text unless pre_text == ',' or !pre_text.end_with? ':'
          contributor = {}
          contributor[:name] = item.text 
          contributor[:b_id] = (item[:href].split("/"))[2]      
          contributors << contributor
        end
        # Alternative way based on intersecting sets
        # set_A = "//a[@class='booklink' and @href[contains(.,'/com/') ]][1]/preceding::text()"
        # set_B = "//a[@class='booklink' and @href[not(contains(.,'/com/')) ]][1]/following::text()"

        # others = book.xpath("#{set_A}[count(.|#{set_B}) = count(#{set_B})]").map do |other|
        #           text = other.inner_text.strip
        #           other = text == "," ? nil : text          
        #         end.compact         
        contributors
      end  

      def details
        details = @nodeset.css('.book_details')[0].inner_html.gsub(/(^\d,\d)|(\D,|,\D)(?=[^\]]*(?:\[|$))/, "<br>").split("<br>").map(&:strip).reject!(&:empty?)
        if details.nil?
          details = @nodeset.css('.book_details')[1].inner_html.gsub(/(^\d,\d)|(\D,|,\D)(?=[^\]]*(?:\[|$))/, "<br>").split("<br>").map(&:strip).reject!(&:empty?)           
        end

        return details     
      end   

      def description
        desc = @nodeset.css('p').last.inner_html #.to_s.gsub(/<br>/,'\\n')
        desc = Sanitize.clean(desc, elements: ['br'])

        if (desc =~ /\p{Word}{3,}/).nil?
          return nil
        else
          return desc
        end
      end   

      def ddcs
        @nodeset.xpath("//a[@class='subjectlink' and @href[contains(.,'/index/') ]]")
      end   

      def collective_work?
        return @nodeset.at_css('h1.book_title').parent.text.include?('Συλλογικό έργο') ? true : false
      end 

      # Special case in which there is no author but there are contributors
      def has_contributors_but_no_authors?
        node_start = "//h1[@class='book_title']/following::text()"
        node_end = "//a[@class='booklink' and @href[contains(.,'/author/') ]][1]/preceding::text()"
        between = (@nodeset.xpath(node_start) & @nodeset.xpath(node_end)).text.strip
                
        if !between.empty? and between.end_with? ':'        
          true
        else
          false
        end
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

    # Raised when a book has no image.
    #
    class NoImageError < StandardError      
      attr_reader :biblionet_id

      def initialize(biblionet_id)        
        msg = "This book has no image. At book #{biblionet_id}"
        super(msg)
      end    
    end     

  end
end


# Both methods write a file
# File.open('book_133435_decoded.html', 'w') { |file| file.write(dec) }
# File.write('filename', 'content')

# puts decode_file('book_133435.html')

# biblionet_id = '123351'

# biblionet_id = '17351'

# biblionet_id = '133435'

# page = Nokogiri::HTML(open("book_#{biblionet_id}.html"))

# book_hash = Hash.new

# book = page.css('//tr/td[width="180"][valign="top"][align="left"]')


# img = (page.xpath("/html/body//img[@src[contains(.,'/covers/')]][1]").first)['src']
# book_hash['image'] = BASE_URL+img

# title = page.css('h1.book_title').text
# book_hash['title'] = title

# author = page.css('a.booklink').first.text
# book_hash['author'] = author

# # others = page.xpath("//a[@class='booklink' and @href[not(contains(.,'/com/')) ]]")

# publisher = page.xpath("//a[@class='booklink' and @href[contains(.,'/com/') ]][1]").text
# book_hash['publisher'] = publisher

# A = "//a[@class='booklink' and @href[contains(.,'/com/') ]][1]/preceding::text()"
# B = "//a[@class='booklink' and @href[not(contains(.,'/com/')) ]][1]/following::text()"

# others =  book.xpath("#{A}[count(.|#{B}) = count(#{B})]").inner_text

# others = others.split(/\n/).map(&:strip).reject!(&:empty?)

# details = page.css('.book_details').inner_html.gsub(/(^\d,\d)|(\D,)|(,\D)/, "<br>").split("<br>").map(&:strip).reject!(&:empty?)
# details_hash = proccess_details(details)

# book_hash['publication_year'] = details_hash['publication_year']
# book_hash['pages'] = details_hash['pages']
# book_hash['isbn'] = details_hash['isbn']
# book_hash['isbn_13'] = details_hash['isbn_13'].nil? ? nil : details_hash['isbn_13']
# book_hash['status'] = details_hash['status']
# book_hash['price'] = details_hash['price']

# contributors = proccess_contributors(others)
# book_hash['contributors'] = contributors

# # puts test.xpath("#{A}[count(.|#{B}) = count(#{B})]")

# # puts author.search('/following::node()')

# desc = page.css('p').last.inner_html #.to_s.gsub(/<br>/,'\\n')
# desc = Sanitize.clean(desc, elements: ['br'])

# if (desc =~ /\p{Word}{3,}/).nil?
#   book_hash['description'] = nil
# else
#   book_hash['description'] = desc
# end

# ddcs = page.xpath("//a[@class='subjectlink' and @href[contains(.,'/index/') ]]").map do |ddc|      
#         # Extract from href the ddc id used by biblionet. --- DdC url http://biblionet.gr/index/id ---
#         ddc_biblionet_id = ddc[:href].split(/\//).last
#         # Extact DdC id and DdC text.     
#         ddc = proccess_ddc(ddc.text)

#         ddc.merge!(b_id: ddc_biblionet_id)

#       end


# book_hash['ddc_ids'] = ddcs
# book_hash['biblionet_id'] = biblionet_id

# book_json = book_hash.to_json

# puts book_json_pretty = JSON.pretty_generate(book_hash)

# File.open("book_#{biblionet_id}.json","w") do |f|
#   f.write(book_json)
# end

# def contributors(n)
#   contributors = []  
#   n.xpath("//a[@class='booklink' and @href[contains(.,'/author/') ]]").each do |item| 
#     pre_text = item.previous.text.strip           
#     contributors << pre_text unless pre_text == ',' or !pre_text.end_with? ':'
#     contributor = {}
#     contributor['name'] = item.text 
#     contributor['b_id'] = (item[:href].split("/"))[2]      
#     contributors << contributor
#   end       
#   contributors
# end  

# c = contributors(n4)

# def proccess_contributors(raw_contributors)
#   contributors  = Hash.new
#   partners      = Array.new
#   job           = "author"
#   raw_contributors.each do |cb|
#     if cb.is_a?(String) and cb.end_with? ":"
#       job = cb[0..-2]
#       partners.clear
#     else
#       partners << cb
#       contributors[job] =  partners.clone
#     end  
#   end unless raw_contributors.nil? or raw_contributors.empty?
  
#   return contributors
# end

# c2 = proccess_contributors(c)

