#!/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'json'
require 'logger'
require 'pp'
require 'marc'
require 'htmlentities'

module Nlg
  module Extractors

    class Base

      attr_reader :url, :nlg_id, :page

      def initialize(id=nil)
        load_page(id)
      end

      def load_page(id=nil)
        load_page_by_id(id) unless id.nil?
      end

      def load_page_by_id(id)
        begin
          @nlg_id = id unless id.nil? # id is expected to be the last number.
          @url = "http://nbib.nlg.gr/Record/#{@nlg_id}/Export?style=MARCXML"

          pp "Downloading page: #{@url}"

          Net::HTTP.start("nbib.nlg.gr") do |http|
            response = http.get("/Record/#{@nlg_id}/Export?style=MARCXML")
            pp response.content_type
            pp response.code
            raise EmptyPageError.new(@url) unless response.content_type == "text/xml" && response.code == "200"

            @page = response.body
          end

        rescue Errno::ENOENT => e
          pp "Page: #{@url} NOT FOUND."
          pp e
        rescue EmptyPageError => e
          pp "Page: #{@url} is EMPTY."
          pp e
          @page = nil
        rescue OpenURI::HTTPError => e
          pp e
          pp e.io.status
        rescue StandardError => e
          pp "Generic error #{e.class}. Will wait for 2 minutes and then try again."
          pp e
          sleep(120)
          retry
        end
      end

      # Decodes text with escaped html entities and returns the decoded text.
      #
      # ==== Params:
      #
      # +encoded_text+:: the text which contains encoded entities
      #
      def decode_text(encoded_text)
        self.class.decode_text(encoded_text)
      end

      def self.decode_text(encoded_text)
        # encoded_text = File.read(encoded_file_path)
        coder = HTMLEntities.new
        coder.decode(encoded_text)
      end

      def present?(value)
        return (not value.nil? and not value.empty?) ? true : false
      end

    end

    # Raised when a page is considered empty.
    #
    class EmptyPageError < StandardError
      attr_reader :url

      def initialize(url)
        @url = url

        msg = "Page: #{url} is not valid xml so it is considered EMPTY."
        super(msg)
      end
    end

    # Raised when something unexpected or in wrong format is parsed.
    #
    class NoIdeaWhatThisIsError < StandardError
      attr_reader :nlg_id, :the_unexpected

      def initialize(nlg_id, the_unexpected)
        @nlg_id = nlg_id
        @the_unexpected = the_unexpected

        msg = "We have no idea what this: #{the_unexpected} is. At book #{nlg_id}"
        super(msg)
      end
    end

  end
end
