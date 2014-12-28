require 'spec_helper'

describe Bookshark::Extractor do
  subject { Bookshark::Extractor.new }
  let(:author_13219) { JSON.parse(open(File.expand_path("test_data/author_13219.json", File.dirname(__FILE__))).read) }

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

  describe '#process_options' do
    context 'with valid options' do
      it 'returns a biblionet url when there is no local option set' do
        expect(subject.send(:process_options, id:56)).to eq("http://www.biblionet.gr/author/56")
      end

      it 'returns a local path when the local option is set to true' do
        expect(subject.send(:process_options, id: 56, local: true)).to eq("#{Bookshark::path_to_storage}/html_author_pages/56")
      end

      it 'returns the given uri' do
        expect(subject.send(:process_options, uri:'http://www.biblionet.gr/book/5487', id: 56, local: true)).to eq("http://www.biblionet.gr/book/5487")
      end

      it 'returns the given uri if uri option is set even if other options are set' do
       expect(subject.send(:process_options, uri:'http://www.biblionet.gr/book/87', id: 56, local: true)).to eq("http://www.biblionet.gr/book/87")
      end            
    end

    context 'with invalid options' do
      it 'returns the given uri' do

      end
    end
  end

end