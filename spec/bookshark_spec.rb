#!/bin/env ruby
# encoding: utf-8

require 'spec_helper'

describe Bookshark::Extractor do
  subject { Bookshark::Extractor.new(format: 'pretty_json') }
  let(:author_13219)      { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/author_13219.json"     , File.dirname(__FILE__))).read)) }
  let(:publisher_20)      { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/publisher_20.json"     , File.dirname(__FILE__))).read)) }
  let(:category_1041)     { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/category_1041.json"    , File.dirname(__FILE__))).read)) }
  let(:book_103788)       { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/book_103788.json"      , File.dirname(__FILE__))).read)) }
  let(:eager_book_184923) { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/eager_book_184923.json", File.dirname(__FILE__))).read)) }
  let(:search_01)         { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/search_01.json"        , File.dirname(__FILE__))).read)) }
  let(:search_ids_01)     { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/search_ids_01.json"    , File.dirname(__FILE__))).read)) }
  let(:empty_book)        { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/empty_book.json"       , File.dirname(__FILE__))).read)) }
  let(:empty_author)      { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/empty_author.json"     , File.dirname(__FILE__))).read)) }
  let(:empty_publisher)   { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/empty_publisher.json"  , File.dirname(__FILE__))).read)) }
  let(:empty_category)    { JSON.pretty_generate(JSON.parse(open(File.expand_path("test_data/empty_category.json"   , File.dirname(__FILE__))).read)) }


  describe '#author' do
    context 'from remote html source' do
      context 'when the author exists' do
        it 'reads html from the web based on given id and extracts author data' do
          expect(subject.author(id: 13219)).to eq author_13219
        end
        it 'reads html from the web based on given uri and extracts author data' do
          expect(subject.author(uri: "http://biblionet.gr/author/13219")).to eq author_13219
        end        
      end
      context 'when the author doesnt exist' do
        it 'returns an empty array' do
          expect(subject.author(id: 0)).to eq empty_author
        end  
      end  
      context 'when no options are set' do
        it 'returns an empty array' do
          expect(subject.author).to eq empty_author
        end  
      end 
      context 'when a the given uri is wrong' do
        it 'returns an empty array' do
          expect(subject.author(uri: "http://google.com")).to eq empty_author
        end  
      end           
    end

    context 'from local storage' do
      it 'reads html from file and extracts author data' do
        file_name = File.expand_path("test_data/author_13219.html", File.dirname(__FILE__))
        expect(subject.author(uri: file_name)).to eq author_13219
      end
    end
  end

  describe '#publisher' do
    context 'extract from remote html source' do
      context 'when the publisher exists' do
        it 'reads html from the web based on given id and extracts publisher data' do
          expect(subject.publisher(id: 20)).to eq publisher_20
        end
        it 'reads html from the web based on given uri and extracts publisher data' do
          expect(subject.publisher(uri: "http://biblionet.gr/com/20")).to eq publisher_20
        end        
      end
      context 'when the publisher doesnt exist' do
        it 'returns an empty array' do
          expect(subject.publisher(id: 0)).to eq empty_publisher
        end  
      end  
      context 'when no options are set' do
        it 'returns an empty array' do
          expect(subject.publisher).to eq empty_publisher
        end  
      end  
      context 'when a the given uri is wrong' do
        it 'returns an empty array' do
          expect(subject.publisher(uri: "http://google.com")).to eq empty_publisher
        end  
      end             
    end    
  end

  describe '#category' do
    context 'extract from remote html source' do
      context 'when the category exists' do
        it 'reads html from the web based on given id and extracts category data' do
          expect(subject.category(id: 1041)).to eq category_1041
        end
        it 'reads html from the web based on given uri and extracts category data' do
          expect(subject.category(uri: "http://biblionet.gr/index/1041")).to eq category_1041
        end
      end
      context 'when the category doesnt exist' do
        it 'returns an empty array' do
          expect(subject.category(id: 0)).to eq empty_category
        end  
      end  
      context 'when no options are set' do
        it 'returns an empty array' do
          expect(subject.category).to eq empty_category
        end  
      end  
      context 'when a the given uri is wrong' do
        it 'returns an empty array' do
          expect(subject.category(uri: "http://google.com")).to eq empty_category
        end  
      end                            
    end 
  end

  describe '#book' do
    context 'extract from remote html source' do
      context 'when book exists' do
        it 'reads html from the web based on given id and extracts book data' do
          expect(subject.book(id: 103788)).to eq book_103788
        end

        it 'reads html from the web based on given uri and extracts book data' do
          expect(subject.book(uri: "http://biblionet.gr/book/103788")).to eq book_103788
        end        

        it 'reads html from the web and eager extracts all book and reference data' do
          expect(subject.book(id: 184923, eager: true)).to eq eager_book_184923
        end

        it 'reads html from the web based on given isbn and extracts book data' do
          expect(subject.book(isbn: '960-14-1157-7')).to eq book_103788
        end 

        it 'reads html from the web based on given isbn-13 and extracts book data' do
          expect(subject.book(isbn: '978-960-14-1157-6')).to eq book_103788
        end         
      end

      context 'when the book doesnt exist' do
        it 'returns an empty array' do
          expect(subject.book(id: 0)).to eq empty_book
        end  
      end  

      context 'when the books isbn is nonsense' do
        it 'returns an empty array' do
          expect(subject.book(isbn: 'wrong-isbn')).to eq empty_book
        end  
      end    

      context 'when no options are set' do
        it 'returns an empty array' do
          expect(subject.book).to eq empty_book
        end  
      end

      context 'when a the given uri is wrong' do
        it 'returns an empty array' do
          expect(subject.book(uri: "http://google.com")).to eq empty_book
        end  
      end            
    end

    context 'extract from local storage (book and bibliographical record)' do
      before do 
        stub_request(:any, /.*/).to_return(body: "errors", status: 422)
      end
      it 'reads html from local storage based on given id and extracts book data' do
        file_name = File.expand_path("test_data/book_103788.html", File.dirname(__FILE__))
        expect(subject.book(uri: file_name)).to eq book_103788
      end
    end

  end 

  describe '#search' do
    context 'search and extract from remote html source' do
      context 'when books are found' do
        it 'builds a search url and extracts book ids from search page' do
          expect(subject.search(title: 'σημεια και τερατα', results_type: 'ids')).to eq search_ids_01
        end

        it 'builds a search url and extracts book data from search page' do
          expect(subject.search(title: 'σημεια και τερατα', results_type: 'metadata')).to eq search_01
        end  
      end
      context 'when no books are found' do  
        it 'returns an empty array' do
          expect(subject.search(isbn: 'some-invalid-isbn')).to eq empty_book
        end  
      end  
      context 'when no options are set' do
        it 'returns an empty array' do
          expect(subject.search).to eq empty_book
        end  
      end         
    end 
  end
 

  describe '#process_options' do
    context 'with valid options' do
      it 'returns a biblionet url when there is no local option set' do
        expect(subject.send(:process_options, {id:56}, 'author')).to eq("http://www.biblionet.gr/author/56")
      end

      it 'returns a local path when the local option is set to true' do
        expect(subject.send(:process_options, {id: 56, local: true}, 'author')).to eq("#{Bookshark::path_to_storage}/html_author_pages/0/author_56.html")
      end

      it 'returns the given uri' do
        expect(subject.send(:process_options, {uri:'http://www.biblionet.gr/book/5487', id: 56, local: true}, 'book')).to eq("http://www.biblionet.gr/book/5487")
      end

      it 'returns the given uri if uri option is set even if other options are set' do
       expect(subject.send(:process_options, {uri:'http://www.biblionet.gr/book/87', id: 56, local: true}, 'book')).to eq("http://www.biblionet.gr/book/87")
      end            
    end

    context 'with invalid options' do
      it 'returns the given uri' do

      end
    end
  end

  describe 'Biblionet::Extractors::BibliographicalBook' do 
    
  end

end