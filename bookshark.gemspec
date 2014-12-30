# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bookshark/version'

Gem::Specification.new do |spec|
  spec.name          = "bookshark"
  spec.version       = Bookshark::VERSION
  spec.authors       = ["Dimitris Klisiaris"]
  spec.email         = ["dklisiaris@gmail.com"]
  spec.summary       = %q{Book metadata extractor.}
  spec.description   = %q{Extracts book, author, publisher and dcc metadata from biblionet.gr.}
  spec.homepage      = "https://github.com/dklisiaris/bookshark"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'nokogiri'
  spec.add_dependency 'sanitize'
  spec.add_dependency 'json'
  spec.add_dependency 'htmlentities'
  spec.add_dependency 'require_all'


  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
end
