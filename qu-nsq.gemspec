# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "qu/version"

Gem::Specification.new do |s|
  s.name        = "qu-nsq"
  s.version     = Qu::VERSION
  s.authors     = ["John Nunemaker"]
  s.email       = ["nunemaker@gmail.com"]
  s.homepage    = "http://github.com/bkeepers/qu"
  s.summary     = "NSQ backend for qu"
  s.description = "NSQ backend for qu"

  s.files         = `git ls-files -- lib | grep nsq`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency 'krakow', '~> 0.3.0'
  s.add_dependency 'qu', Qu::VERSION

  s.add_development_dependency 'nsq-cluster'
end
