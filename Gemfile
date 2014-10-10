source "http://rubygems.org"
gemspec :name => 'qu'

Dir['qu-*.gemspec'].each do |gemspec|
  plugin = gemspec.scan(/qu-(.*)\.gemspec/).flatten.first
  gemspec(:name => "qu-#{plugin}", :development_group => plugin)
end

group :test do
  gem 'activesupport', :require => false
  gem 'statsd-ruby', :require => false
  gem 'rake'
  gem "rspec", "~> 2.14.1"
end

# don't require snappy (doesn't build on osx)
gem 'krakow', :git => 'https://github.com/chrisroberts/krakow', :ref => 'fae45fe'
