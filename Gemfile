source 'https://rubygems.org'

group :development, :test do
  if RUBY_VERSION >= '1.9'
    gem 'rake'
  else
    gem 'rake', "< 10.0"
    gem 'highline', "< 1.7"
  end
  gem 'rspec-puppet'
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'rspec-system-puppet'
  gem 'rspec-system-serverspec', :require => false
  if RUBY_VERSION >= '1.9'
    gem 'coveralls', :require => false
  end
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
