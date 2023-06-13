Gem::Specification.new do |s|
  s.name        = 'wealthsimple_ruby_client'
  s.version     = '0.0.1'
  s.summary     = 'Wealthsimple client!'
  s.description = 'Unofficial, unsafe, hacky, WealthSimple Ruby client'
  s.authors     = ['Michele Porelli']
  s.email       = 'michele@porelli.eu'
  s.files       = ['lib/wealthsimple_ruby_client.rb']
  s.homepage    = 'https://rubygems.org/gems/wealthsimple_ruby_client'
  s.license     = 'GPLv3'
  s.add_dependency 'faraday', '~> 2.7.4'
  s.add_dependency 'faraday-retry', '~> 2.1.0'
  s.add_dependency 'deep_merge', '~> 1.2.2'
  s.add_dependency 'rubyXL', '~> 3.4.25'
end