# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef/aws/version'

Gem::Specification.new do |spec|
  spec.name          = "chef-aws"
  spec.version       = Chef::AWS::VERSION
  spec.authors       = ["Inetsys"]
  spec.email         = ["sistemas@inetsys.es"]
  spec.summary       = "Utils for Chef and AWS"
  spec.description   = "Utils for Chef and AWS"
  spec.homepage      = "http://www.inetsys.es"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  #spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  #spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency "aws-sdk", "~> 2"
  spec.add_dependency "logger", "~> 1.2"
  #spec.add_runtime_dependency 'colored', '~> 1.2'
end
