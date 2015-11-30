# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opsmanager_client/client/version'

Gem::Specification.new do |spec|
  spec.name          = 'opsmanager_client'
  spec.version       = OpsmanagerClient::Client::VERSION
  spec.authors       = ['Chris Brown']
  spec.email         = ['cb@pivotallabs.com']
  spec.summary       = 'DSL for Pivotal Ops Manager'
  spec.licenses      = ['Copyright (c) Pivotal Software, Inc.']
  spec.description   = 'Interact with the Pivotal Ops Manager from Ruby'
  spec.homepage      = ''

  spec.metadata['allowed_push_host'] = 'https://cf-london@git.fury.io'

  spec.files         = Dir.glob('lib/**/*') + ['LICENSE']
  spec.executables   = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'gemfury', '~> 0.4.25'
  spec.add_development_dependency 'guard-rspec', '~> 4.2'
  spec.add_development_dependency 'pry', '~> 0.9.12.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.1'
  spec.add_development_dependency 'vcr', '~> 2.9.0'
  spec.add_development_dependency 'webmock', '~> 1.17.4'
  spec.add_development_dependency 'gem-release', '~> 0.7'

  spec.add_dependency 'httmultiparty', '~> 0.3'
end
