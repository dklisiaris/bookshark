#!/bin/env ruby
# encoding: utf-8

require_relative 'base'

module Nlg
  module Extractors

    class BookExtractor < Base
      attr_reader :book

      def initialize(id=nil)
        super(id)
        extract_book unless id.nil? or @page.nil?
      end

      def load_and_extract_book(id=nil)
        load_page(id)
        extract_book unless id.nil? or @page.nil?
      end

      def extract_book(nlg_id=@nlg_id, book_page=@page)
        puts "should extract book #{nlg_id} from nlg"
      end

    end
  end
end
