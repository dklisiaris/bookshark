require "bookshark/version"
require 'bookshark/storage/file_manager'
require 'bookshark/extractors/author_extractor'
require 'bookshark/extractors/ddc_extractor'
require 'bookshark/extractors/book_extractor'

module Bookshark
  EXTRACTOR_DEFAULTS = {
    site: 'biblionet',
    format: 'hash'
  }

  def self.root
    File.dirname __dir__
  end  

  def self.path_to_storage
    File.join root, 'lib/bookshark/storage'
  end


  class Extractor
    include FileManager
    attr_accessor :site

    def initialize(options = {})
      options = EXTRACTOR_DEFAULTS.merge(options)
      @site = options[:site]
      @formal = options[:format]
    end

    def author(options = {})
      uri = process_options(options, __method__)
      options[:format] ||= @format

      author_extractor = Biblionet::Extractors::AuthorExtractor.new
      author = author_extractor.load_and_extract_author(uri)      
      author.to_json if options[:format] == 'json'

      return author
    end

    def book(uri=nil, options = {})
      bp = Biblionet::Extractors::BookExtractor.new
      bp.load_and_extract_book(uri)
    end

    def ddcs(uri=nil, options = {})
      dp = Biblionet::Extractors::DDCExtractor.new
      dp.extract_ddcs_from(uri)
    end

    def parse_all_ddcs(will_save=false)
      # list_directories('raw_ddc_pages').each do |dir|
        # p dir
      # end
      dp = Biblionet::Extractors::DDCExtractor.new
      all_ddcs = Hash.new
      
      list_files(path: 'storage/raw_ddc_pages', extension: 'html', all:true).each do |file|
        ddcs = dp.extract_ddcs_from(file)                 
        all_ddcs.merge!(ddcs) unless ddcs.nil? or ddcs.empty?
      end

      if will_save
        all_ddcs_json = all_ddcs.to_json
        save_to('storage/all_ddcs.json',all_ddcs_json)
      end

      all_ddcs
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
      # puts caller_locations(1,1)[0].label
      # options[:format] ||= @format
      puts caller

      options[:local] ||= false
      url = "#{Bookshark::path_to_storage}/html_author_pages/#{options[:id].to_s}" unless not options[:local] or options[:id].nil?
      url = "http://www.biblionet.gr/author/#{options[:id].to_s}" unless options[:local] or options[:id].nil?
      uri = options[:uri] ||= url
      return uri
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

#         def ddcs(uri=nil)
#           dp = BiblionetParser::Core::DDCParser.new
#           dp.extract_ddcs_from(uri)
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
# ddcs = bib.parse_all_ddcs(true)

# p bib.list_files(path: 'raw_html_pages/2', extension:'html')
# p bib.list_directories
# p ddcs[787]
# ddcs = 'test'
# bib.save_to('all_ddcs_test.json', ddcs)

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
# pp all = ddcp.ddcs
# pp cur = ddcp.ddcs.values.last
# pp sel = ddcp.ddcs["2703"]

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