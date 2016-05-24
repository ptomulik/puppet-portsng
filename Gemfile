source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place, fake_version = nil)
  if place =~ /^(git[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place, { :require => false }]
  end
end

group :development, :unit_tests do
  if RUBY_VERSION >= '1.9'
    gem 'rake'
  else
    gem 'rake', "< 10.0"
    gem 'highline', "< 1.7"
  end
  gem 'rspec-puppet'
  gem 'puppetlabs_spec_helper',  :require => false
  if RUBY_VERSION >= '1.9'
    gem 'coveralls', :require => false
  end
end

group :acceptance_tests do
  gem 'beaker-rspec',                 *location_for(ENV['BEAKER_RSPEC_VERSION'] || '>= 3.4')
  gem 'beaker',                       *location_for(ENV['BEAKER_VERSION'])
  gem 'serverspec',                   :require => false
  gem 'beaker-puppet_install_helper', :require => false
end

gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'])
gem 'facter', *location_for(ENV['FACTER_GEM_VERSION'])

if File.exists? "#{__FILE__}.local"
  eval(File.read("#{__FILE__}".local), binding)
end

# vim:ft=ruby
