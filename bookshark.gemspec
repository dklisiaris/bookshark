# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bookshark/version'

Gem::Specification.new do |spec|
  spec.name          = "bookshark"
  spec.version       = Bookshark::VERSION
  spec.authors       = ["Dimitris Klisiaris"]
  spec.email         = ["dklisiaris@gmail.com"]
  spec.summary       = %q{Book metadata extractor from biblionet.gr.}
  spec.description   = %q{Extracts book, author, publisher and category metadata from biblionet.gr.}
  spec.homepage      = "https://github.com/dklisiaris/bookshark"
  spec.license       = "MIT"

  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.6", ">= 1.6.6"
  spec.add_dependency "sanitize", "~> 3.1"
  spec.add_dependency "json", "~> 1.8"
  spec.add_dependency "htmlentities", "~> 4.3"

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec', "~> 3.2"
end
