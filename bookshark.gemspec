# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bookshark/version'

Gem::Specification.new do |spec|
  spec.name          = 'bookshark'
  spec.version       = Bookshark::VERSION
  spec.authors       = ['Dimitris Klisiaris']
  spec.email         = ['dklisiaris@gmail.com']
  spec.summary       = 'Book metadata extractor from biblionet.gr.'
  spec.description   = 'Extracts book, author, publisher and category metadata from biblionet.gr.'
  spec.homepage      = 'https://github.com/dklisiaris/bookshark'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'htmlentities', '~> 4.3'
  spec.add_dependency 'json', '~> 2.3'
  spec.add_dependency 'marc', '~> 1.0'
  spec.add_dependency 'nokogiri', '~> 1.10', '>= 1.10.10'
  spec.add_dependency 'sanitize', '~> 5.2'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'pry-byebug', '~> 3.9'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'webmock', '~> 3.8'
end
