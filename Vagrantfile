# -*- mode: ruby -*-
# vi: set ft=ruby :

##############################################################################
# Starting particular virtual machines in shell:
#
#   vagrant up freebsd-10.2-amd64-ports # or
#   vagrant up freebsd-10.3-amd64-ports # etc...
#
# Logging in to virtual machines
#
#   vagrant ssh freebsd-10.2-amd64-ports # or
#   vagrant ssh freebsd-10.3-amd64-ports # etc...
##############################################################################

# rubocop: disable BlockLength
Vagrant.configure(2) do |config|
  boxes = []
  versions = ['9.0', '9.1', '9.2', '9.3', '10.1', '10.2', '10.3', '11.0', '11.1', '12.0']
  versions.map do |version|
    ['amd64'].map do |arch|
      box = "freebsd-#{version}-#{arch}-ports"
      config.vm.define box, :autostart => false do |cfg|
        cfg.vm.hostname = "freebsd-#{version}"
        cfg.vm.box = "ptomulik/#{box}"
        pkg_install = version =~ /9.[0-2]/ ? 'pkg_add -r' : 'pkg install -y'
        pkg_update = version =~ /9.[0-2]/ ? '' : 'pkg update'
        pkg_upgrade = version =~ /9.[0-2]/ ? '' : 'pkg upgrade -y'
        portsnap_update = if version =~ /9.[0-2]/
                            ''
                          else
                            'portsnap --interactive fetch update'
                          end
        config.vm.provision 'shell', :inline => <<-SHELL
          #{pkg_update}
          #{pkg_upgrade}
          #{pkg_install} rubygem-bundler
          #{pkg_install} git
          #{portsnap_update}
        SHELL
      end
      boxes.push(box)
    end
  end

  config.vm.synced_folder '.', '/vagrant', :type => 'rsync'

  # Present machines that may be used...
  if ARGV.include?('up')
    i = ARGV.index('up')
    unless (ARGV.size > i + 1) && boxes.include?(ARGV[-1])
      puts('No default machine defined, use one of the following:')
      boxes.map do |name|
        puts("vagrant up #{name}\n")
      end
    end
  end
end
# rubocop: enable BlockLength
