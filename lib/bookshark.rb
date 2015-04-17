require "bookshark/version"
require 'bookshark/storage/file_manager'

require 'bookshark/extractors/author_extractor'
require 'bookshark/extractors/category_extractor'
require 'bookshark/extractors/book_extractor'
require 'bookshark/extractors/publisher_extractor'
require 'bookshark/extractors/search'

require 'bookshark/crawlers/base'
require 'bookshark/crawlers/publisher_crawler'

module Bookshark
  DEFAULTS ||= {
    site: 'biblionet',
    format: 'hash'
  }

  def self.root
    # File.dirname __dir__ # Works only on ruby > 2.0.0
    File.expand_path(File.join(File.dirname(__FILE__), '../'))
  end  
 
  def self.path_to_storage
    File.join root, 'lib/bookshark/storage'
  end


  class Extractor
    include FileManager
    attr_accessor :site, :format    

    def initialize(options = {})
      options = DEFAULTS.merge(options)
      @site   = options[:site]
      @format = options[:format]
    end

    def author(options = {})
      uri = process_options(options, __method__)
      options[:format] ||= @format

      author_extractor = Biblionet::Extractors::AuthorExtractor.new
      author = author_extractor.load_and_extract_author(uri) 
          
      response = {}      
      response[:author] = !author.nil? ? [author] : []
      response = change_format(response, options[:format])
      return response
    end

    def publisher(options = {})
      uri = process_options(options, __method__)
      options[:format] ||= @format

      publisher_extractor = Biblionet::Extractors::PublisherExtractor.new
      publisher = publisher_extractor.load_and_extract_publisher(uri)
      
      response = {}      
      response[:publisher] = !publisher.nil? ? [publisher] : []
      response = change_format(response, options[:format])
      response = publisher_extractor.decode_text(response)

      return response
      # return uri     
    end    

    def book(options = {})
      book_extractor = Biblionet::Extractors::BookExtractor.new
      
      if book_extractor.present?(options[:isbn])
        search_engine = Biblionet::Extractors::Search.new
        options[:id]  = search_engine.search_by_isbn(options[:isbn])
      end  

      uri = process_options(options, __method__)
      options[:format]  ||= @format
      options[:eager]   ||= false            
      
      if options[:eager]
        book = eager_extract_book(uri)
      else        
        book = book_extractor.load_and_extract_book(uri)
      end

      response = {}      
      response[:book] = !book.nil? ? [book] : []
      response = change_format(response, options[:format])
      response = book_extractor.decode_text(response)
      
      return response            
    end

    def category(options = {})
      uri = process_options(options, __method__)
      options[:format] ||= @format      

      category_extractor = Biblionet::Extractors::CategoryExtractor.new
      category = category_extractor.extract_categories_from(uri)

      response = {}      
      response[:category] = !category.nil? ? [category] : []
      response = change_format(response, options[:format])
      
      return response        
    end

    def search(options = {})
      options[:format]        ||= @format
      options[:results_type]  ||= 'metadata'           

      search_engine  = Biblionet::Extractors::Search.new
      search_results = search_engine.perform_search(options)

      response = {}      
      response[:book] = search_results
      response = change_format(response, options[:format])
      
      return response       
    end

    def books_from_storage
      extract_from_storage_and_save('book', 'html_book_pages', 'json_book_pages')
    end

    def authors_from_storage
      extract_from_storage_and_save('author', 'html_author_pages', 'json_author_pages')
    end

    def publishers_from_storage
      extract_from_storage_and_save('publisher', 'html_publisher_pages', 'json_publisher_pages')
    end

    def categories_from_storage
      extract_from_storage_and_save('category', 'html_category_pages', 'json_category_pages')
    end

    def extract_from_storage_and_save(metadata_type, source_dir, target_dir)      
      list_directories(path: Bookshark.path_to_storage + '/' + source_dir).each do |dir|
        dir_to_save = dir.gsub(source_dir, target_dir)        

        list_files(path: dir, extension: 'html', all:true).each do |file|
          puts "Extracting from file: " + file.to_s          

          # Extract publisher metadata form local file.
          options = {uri: file, format: 'pretty_json', local: true}          
          
          case metadata_type
          when 'author'
            record = author(options)
          when 'publisher'
            record = publisher(options)
          when 'book'
            record = book(options)
          when 'category'
            record = category(options)       
          end  

          # Prepare a path to save the new file.
          filename  = File.basename(file,".*")
          path_to_save = "#{dir_to_save}#{filename}.json"
      
          # Save to file.        
          save_to("#{path_to_save}", record)
          
        end # unless File.directory?(dir_to_save) # if dir.end_with? '/195/'
      end
    end

    def parse_all_categories(will_save=false)
      # list_directories('raw_ddc_pages').each do |dir|
        # p dir
      # end
      category_extractor = Biblionet::Extractors::CategoryExtractor.new
      all_categories = Hash.new
      
      list_files(path: 'storage/raw_ddc_pages', extension: 'html', all:true).each do |file|
        categories = category_extractor.extract_categories_from(file)                 
        all_categories.merge!(categories) unless categories.nil? or categories.empty?
      end

      if will_save
        all_categories_json = all_categories.to_json
        save_to('storage/all_categories.json',all_categories_json)
      end

      all_categories
    end

    def parse_all_books
      bp = Biblionet::Extractors::BookExtractor.new

      list_directories(path: 'storage/raw_html_pages').each do |dir|
        dir_to_save = dir.gsub(/raw_html_pages/, 'books')
        
        list_files(path: dir, extension: 'html', all:true).each do |file|        
      
          # Load the book from html file and parse the data.
          # pp "Parsing book: #{file}"
          pp file
          book = bp.load_and_extract_book(file)
      
          # Prepare a path to save the new file.
          filename  = File.basename(file,".*")
          path_to_save = "#{dir_to_save}#{filename}.json"
      
          # Save to file.        
          bp.save_to("#{path_to_save}", JSON.pretty_generate(book))
          # pp "Book #{file} saved!"
        end unless File.directory?(dir_to_save) # if dir.end_with? '/195/'
      end
    end

    private

    def process_options(options = {}, caller = nil)
      # puts "Called from method: " + caller.to_s

      id = options[:id]

      if id
        case caller.to_s
        when 'author'
          url_method    = 'author'
          local_path    = "html_author_pages/#{((id-1)/1000)}/author_#{id}.html"
        when 'publisher'
          url_method    = 'com'
          local_path    = "html_publisher_pages/#{((id-1)/100)}/publisher_#{id}.html"
        when 'book'
          url_method    = 'book'
          local_path    = "html_book_pages/#{((id-1)/1000)}/book_#{id}.html"
        when 'category'
          url_method    = 'index' 
          local_path    = "html_ddc_pages/#{((id-1)/1000)}/ddc_#{id}.html"       
        else
          puts "Called from unknown method. Probably its rspec."
        end      

        options[:local] ||= false
        url = "#{Bookshark::path_to_storage}/#{local_path}" if options[:local]
        url = "http://www.biblionet.gr/#{url_method}/#{id}" unless options[:local]
      end
      uri = options[:uri] ||= url

      return uri
    end  

    def change_format(hash, format)
      case format
      when 'hash'
        return hash
      when 'json'
        hash = hash.to_json
      when 'pretty_json'
        hash = JSON.pretty_generate(hash) 
      end
      return hash
    end    

    def eager_extract_book(uri)
      book_extractor      = Biblionet::Extractors::BookExtractor.new
      author_extractor    = Biblionet::Extractors::AuthorExtractor.new
      publisher_extractor = Biblionet::Extractors::PublisherExtractor.new
      category_extractor  = Biblionet::Extractors::CategoryExtractor.new

      book = book_extractor.load_and_extract_book(uri)

      tmp_data = []                 
      book[:author].each do |author|
        tmp_data << author_extractor.load_and_extract_author("http://www.biblionet.gr/author/#{author[:b_id]}") 
      end
      book[:author] = tmp_data      
      
      tmp_data, tmp_hash = [], {}      
      book[:contributors].each do |job, contributors|
        contributors.each do |contributor|
          tmp_data << author_extractor.load_and_extract_author("http://www.biblionet.gr/author/#{contributor[:b_id]}")
        end
        tmp_hash[job] = tmp_data
        tmp_data = []
      end
      book[:contributors] = tmp_hash

      tmp_data, tmp_hash = [], {} 
      book[:category].each do |category|
        tmp_data << category_extractor.extract_categories_from("http://www.biblionet.gr/index/#{category[:b_id]}")
      end
      book[:category] = tmp_data 
      
      tmp_data = [] 
      tmp_data << publisher_extractor.load_and_extract_publisher("http://www.biblionet.gr/com/#{book[:publisher][:b_id]}")  
      book[:publisher] = tmp_data

      book
    end       
  
  end


  class Crawler
    include FileManager
    attr_accessor :site

    def initialize(options = {})
      options = DEFAULTS.merge(options)
      @site   = options[:site]    
    end

    def publishers
      # crawler = Biblionet::Crawlers::Base.new(start:1, finish:100, step:10)
      # crawler.spider do |url, path|
      #   puts "URL: #{url}, PATH: #{path}"
      # end
      # puts Biblionet::Extractors::Base.new("http://www.biblionet.gr/com/245").page
      crawler = Biblionet::Crawlers::PublisherCrawler.new
      crawler.crawl_and_save
    end

  end  

#   module Biblionet
#     class Extract
#       class << self      
#         def author(uri=nil)
#           author_extractor = BiblionetParser::Core::AuthorExtractor.new
#           author_extractor.load_and_extract_author(uri)
#         end

#         def book(uri=nil)
#           bp = BiblionetParser::Core::BookParser.new
#           bp.load_and_parse_book(uri)
#         end

#         def categories(uri=nil)
#           category_extractor = BiblionetParser::Core::DDCParser.new
#           category_extractor.extract_categories_from(uri)
#         end

#       end
#     end
#   end  
end


# ae = BiblionetParser::Core::AuthorExtractor.new
# ae.load_and_extract_author('storage/html_author_pages/0/author_5.html')


# Biblionet::Extract.author('storage/html_author_pages/0/author_5.html')
# Biblionet::Extract.author('storage/html_author_pages/2/author_2423.html')
# Biblionet::Extract.author('storage/html_author_pages/0/author_764.html')
# Biblionet::Extract.author('storage/html_author_pages/0/author_435.html')

# bib = Bibliotheca.new
# categories = bib.parse_all_categories(true)

# p bib.list_files(path: 'raw_html_pages/2', extension:'html')
# p bib.list_directories
# p categories[787]
# categories = 'test'
# bib.save_to('all_categories_test.json', categories)

# bp = BiblionetParser::Core::BookParser.new
# bp.load_and_parse_book('storage/raw_html_pages/96/book_96592.html') # BAD Book --no image
# bp.load_and_parse_book('storage/raw_html_pages/96/book_96937.html') # BAD Book --award
# bp.load_and_parse_book('storage/raw_html_pages/78/book_78836.html') # BAD Book --multiple awards
# bp.load_and_parse_book('storage/raw_html_pages/149/book_149345.html') # BAD Book --2 sets of details (ebooks, normals)
# bp.load_and_parse_book('storage/raw_html_pages/149/book_149402.html') # BAD Book --2 sets of details (normals, reviews)
# bp.load_and_parse_book('storage/raw_html_pages/149/book_149278.html') # BAD Book --3 sets of details (ebooks, normals, reviews)
# bp.load_and_parse_book('storage/raw_html_pages/149/book_149647.html')
# puts JSON.pretty_generate(bp.book)

# bp.load_and_parse_book('storage/raw_html_pages/70/book_70076.html') # BAD Book --Has comma inside award

# bp.load_and_parse_book('storage/raw_html_pages/70/book_70828.html') # BAD Book --No author. Collective Work
# puts JSON.pretty_generate(bp.book)

# bp.load_and_parse_book('storage/raw_html_pages/70/book_70829.html') # BAD Book --No author, No publisher. Collective Work
# puts JSON.pretty_generate(bp.book)

# bp.load_and_parse_book('storage/raw_html_pages/145/book_145326.html') # BAD Book --ISMN istead of ISBN

# bp.load_and_parse_book('storage/raw_html_pages/45/book_45455.html') # BAD Book --No author. Has contributors.
# puts JSON.pretty_generate(bp.book)


# bp.load_and_parse_book('storage/raw_html_pages/132/book_132435.html') # BAD Book --Two authors.
# puts JSON.pretty_generate(bp.book)

# bp.load_and_parse_book('storage/raw_html_pages/133/book_133435.html') # GOOD Book

# puts JSON.pretty_generate(bp.book)

# ddcp = BiblionetParser::Core::DDCParser.new('storage/raw_ddc_pages/0/ddc_298.html')
# pp all = ddcp.categories
# pp cur = ddcp.categories.values.last
# pp sel = ddcp.categories["2703"]

# bp.parse_book('12351', bp.page)

# bp.save_page('storage/mits_ts/mits1.json')

# pp bp.url='http://www.biblionet.gr/book/123351'
# pp bp.page

# pp bib.list_directories(path: 'storage/raw_html_pages')
# pp bib.list_files(path: "storage/raw_html_pages/24/", extension: 'html')

# bib = Bibliotheca.new
# bib.parse_all_books

# Good cases:
# 'storage/raw_html_pages/123/book_123351.html'
# 'storage/raw_html_pages/17/book_17351.html'
# 'storage/raw_html_pages/133/book_133435.html'

# Special book cases to check out:
# 'storage/raw_html_pages/96/book_96592.html' --no image
# 'storage/raw_html_pages/96/book_96937.html'

# Problematic at biblionet
# http://biblionet.gr/book/196388
# http://biblionet.gr/book/196386
# http://biblionet.gr/book/195525