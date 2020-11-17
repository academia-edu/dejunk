# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dejunk/version'

Gem::Specification.new do |spec|
  spec.name          = "dejunk"
  spec.version       = Dejunk::VERSION
  spec.required_ruby_version = '~> 2.3'
  spec.authors       = ["David Judd"]
  spec.email         = ["david@academia.edu"]

  spec.summary       = 'Detect keyboard mashing and other junk in your data.'
  spec.homepage      = 'https://github.com/academia-edu/dejunk'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activesupport'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
