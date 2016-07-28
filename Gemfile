source 'https://rubygems.org'

puppetversion = ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : ['>= 4.4.1']
gem "puppet", puppetversion
gem "puppetlabs_spec_helper"
gem "hiera-puppet-helper"
gem "fakefs"
gem "rspec"
gem "rspec-puppet"


# JSON must be 1.x on Ruby 1.9
if RUBY_VERSION < '2.0'
  gem 'json', '~> 1.8'
  gem 'json_pure', '~> 1.0'
  gem 'rubocop', '0.41'
end
