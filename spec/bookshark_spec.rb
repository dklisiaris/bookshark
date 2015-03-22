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


  describe '#author' do
    context 'from remote html source' do
      it 'reads html from the web and extracts author data' do
        expect(subject.author(id: 13219)).to eq author_13219
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
      it 'reads html from the web and extracts publisher data' do
        expect(subject.publisher(id: 20)).to eq publisher_20
      end
    end    
  end

  describe '#category' do
    context 'extract from remote html source' do
      it 'reads html from the web and extracts category data' do
        expect(subject.category(id: 1041)).to eq category_1041
      end
    end 
  end

  describe '#book' do
    context 'extract from remote html source' do
      it 'reads html from the web and extracts book data' do
        expect(subject.book(id: 103788)).to eq book_103788
      end

      it 'reads html from the web and eager extracts all book and reference data' do
        expect(subject.book(id: 184923, eager: true)).to eq eager_book_184923
      end
    end
  end 

  describe '#search' do
    context 'extract from remote html source' do
      it 'builds a search url and extracts book ids from search page' do
        expect(subject.search(title: 'σημεια και τερατα', results_type: 'ids')).to eq search_ids_01
      end

      it 'builds a search url and extracts book data from search page' do
        expect(subject.search(title: 'σημεια και τερατα', results_type: 'metadata')).to eq search_01
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

end