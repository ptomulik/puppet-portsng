$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'patches/lib'))
require 'beaker-rspec'
require 'beaker-rspec/helpers/serverspec'
require 'specinfra_patch.rb' if RUBY_VERSION < '1.9'

# Install Puppet on all hosts
hosts.each do |host|
  if host['platform'] =~ /freebsd/
    default_puppet = host['platform'] =~ /9\.[0-1]/ ? 'puppet' :
                     (host['platform'] =~ /10\.[0-4]/ ? 'puppet4' : 'puppet5')
    # install_puppet does not work on FreeBSD (it uses sysutils/puppet port
    # which doesn't seem to exist)
    host.install_package(ENV['BEAKER_puppet'] || default_puppet)
  else
    install_puppet_on(host)
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    hosts.each do |host|
      install_dev_puppet_module_on(host, :source => proj_root,
                                         :module_name => 'portsng')
      puppet_version = Gem::Version.new(on(host, puppet('--version')).stdout)
      # Puppet < 2.7.14 has no "module" subcommand, and we need
      # "puppet-module" gem to install modules.
      v2x7x14 = Gem::Version.new('2.7.14')
      if puppet_version < v2x7x14
        gemglob = '/usr/local/lib/ruby/gems/*/gems/puppet-module*'
        pattern = 'http:\\/\\/\\(forge\\.puppetlabs\\.com\\)'
        host.shell 'gem install puppet-module'
        host.shell "find #{gemglob} -name '*.rb' | " \
                   "xargs sed -e 's/#{pattern}/https:\\/\\/\\1/g' -i ''"
      end
      # Install dependencies
      moddeps = %w(portsutil backports)
      # The gem puppet-module does not seem to handle dependencies
      moddeps << 'vash' if puppet_version < v2x7x14
      moddeps.each do |modname|
        mn = "ptomulik-#{modname}"
        if puppet_version < v2x7x14
          moduledir = '/usr/local/etc/puppet/modules'
          host.shell "cd  #{moduledir} && puppet module install #{mn}"
        else
          install_puppet_module_via_pmt_on(host, :module_name => mn)
        end
      end
    end
  end
end
