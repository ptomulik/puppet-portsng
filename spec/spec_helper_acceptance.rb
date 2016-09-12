require 'beaker-rspec'
require 'beaker-rspec/helpers/serverspec'
require 'specinfra_patch'

# Install Puppet on all hosts
hosts.each do |host|
  puts "PLATFORM: #{host['platform']}"
  if host['platform'] =~ /freebsd/
    # install_puppet does not work on FreeBSD (it uses sysutils/puppet port
    # which doesn't seem to exist)
    host.install_package(ENV['BEAKER_puppet'] || 'puppet37')
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
      # Install dependencies
      on host, puppet('module', 'install', 'ptomulik-portsutil')
      on host, puppet('module', 'install', 'ptomulik-backport_package_settings')
    end
  end
end
