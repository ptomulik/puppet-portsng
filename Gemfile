source ENV['GEM_SOURCE'] || 'https://rubygems.org'

def location_for(place, fake_version = nil)
  if place =~ /^(git[:@][^#]*)#(.*)/
    [fake_version, { :git => Regexp.last_match(1),
                     :branch => Regexp.last_match(2),
                     :require => false }].compact
  elsif place =~ %r{^file://(.*)}
    ['>= 0', { :path => File.expand_path(Regexp.last_match(1)),
               :require => false }]
  else
    [place, { :require => false }]
  end
end

def ver(s); Gem::Version.new(s.dup); end

group :development, :test do
  # http://stackoverflow.com/questions/30928415/how-to-setup-puppet-rspec-correctly
  gem 'rspec', '~> 2.0' if ver(RUBY_VERSION) >= ver('1.8.7') && ver(RUBY_VERSION) < ver('1.9')
  if ver(RUBY_VERSION) >= ver('1.9')
    gem 'rake'
    gem 'puppetlabs_spec_helper', :require => false
  else
    gem 'rake', '< 10.0'
    gem 'puppetlabs_spec_helper', '< 2.0.0', :require => false
  end
  if ver(RUBY_VERSION) >= ver('1.9') && ver(RUBY_VERSION) < ver('2.0')
    gem 'tins', '< 1.7.0'
    gem 'term-ansicolor', '< 1.4.0'
  end
  gem 'json_pure', '< 2.0.0' if ver(RUBY_VERSION) < ver('2.0')
  if ENV['PUPPET_GEM_VERSION'] and ENV['PUPPET_GEM_VERSION'] =~ /^\s*(~>\s*3\.[01])|(<\s*3\.2(\.0)?)|(<=\s*3\.1)/
    # This is hacky... but I see no way to check what version of puppet is
    # going to be installed (i.e. what version bundler is going to select).
    gem 'rspec-puppet', '< 2.6.5'
  else
    gem 'rspec-puppet'
  end
  gem 'coveralls', :require => false if ver(RUBY_VERSION) >= ver('1.9')
  gem 'rubocop', :require => false if ver(RUBY_VERSION) >= ver('2.2.0')
end

group :acceptance do
  if ver(RUBY_VERSION) < ver('1.9')
    gem 'nokogiri', '< 1.6', :require => false
  elsif ver(RUBY_VERSION) < ver('2.1')
    gem 'nokogiri', '< 1.7', :require => false
  end
  if ver(RUBY_VERSION) < ver('2.1')
    gem 'jwt', '< 2.0', :require => false
  end
  if ver(RUBY_VERSION) < ver('1.9')
    gem 'beaker-rspec', *location_for(ENV['BEAKER_RSPEC_VERSION'])
    gem 'beaker', *location_for(ENV['BEAKER_VERSION'] || '~> 1')
  elsif ver(RUBY_VERSION) < ver('2.2.5')
    gem 'beaker-rspec', *location_for(ENV['BEAKER_RSPEC_VERSION'] || '>= 3.4')
    gem 'beaker', *location_for(ENV['BEAKER_VERSION'] || '~> 2')
  else
    gem 'beaker-rspec', *location_for(ENV['BEAKER_RSPEC_VERSION'] || '>= 3.4')
    gem 'beaker', *location_for(ENV['BEAKER_VERSION'] || '>= 3.2.0')
  end
end

if ver(RUBY_VERSION) >= ver('2.0')
  gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'])
elsif ver(RUBY_VERSION) >= ver('1.9')
  gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'] || '~>4.4.0')
else
  gem 'puppet', *location_for(ENV['PUPPET_GEM_VERSION'] || '~>3.8.0')
end

# vim:ft=ruby
