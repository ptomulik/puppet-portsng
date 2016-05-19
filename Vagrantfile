# -*- mode: ruby -*-
# vi: set ft=ruby :

##############################################################################
# Starting particular virtual machines in shell:
#
#   vagrant up freebsd-10.2 # or
#   vagrant up freebsd-10.3 # or
#   vagrant up freebsd-11.0
#
# Logging in to virtual machines
#
#   vagrant ssh freebsd-10.2 # or
#   vagrant ssh freebsd-10.3 # or
#   vagrant ssh freebsd-11.0
##############################################################################

Vagrant.configure(2) do |config|

  config.vm.guest     = :freebsd
  config.ssh.shell    = 'sh'

  config.vm.define 'freebsd-10.2', autostart: false do |x|
    x.vm.hostname = 'freebsd-10.2'
    x.vm.box = 'freebsd/FreeBSD-10.2-RELEASE'
  end

  config.vm.define 'freebsd-10.3', autostart: false do |x|
    x.vm.hostname = 'freebsd-10.3'
    x.vm.box = 'freebsd/FreeBSD-10.3-RELEASE'
  end

  config.vm.define 'freebsd-11.0', autostart: false do |x|
    x.vm.hostname = 'freebsd-11.0'
    x.vm.box = 'freebsd/FreeBSD-11.0-CURRENT'
  end

  config.vm.synced_folder ".", "/vagrant", :type => 'rsync'
  config.vm.base_mac  = '5CA1AB1E0001'
  config.vm.network :private_network, :bridge => 'enp4s0', :mac => "5CA1AB1E0001", :ip => "10.0.1.13"

  config.vm.provision "shell", inline: <<-SHELL
    pkg update
    pkg upgrade -y
    pkg install -y port-maintenance-tools
    pkg install -y rubygem-bundler
    pkg install -y git
    test -x /usr/ports && portsnap --interactive fetch update  # order is
    test -x /usr/ports || portsnap --interactive fetch extract # important!!!
  SHELL

  config.vm.provider :virtualbox do |vb, override|
    # vb.customize ["startvm", :id, "--type", "gui"]
    vb.customize ["modifyvm", :id, "--memory", "512"]
    vb.customize ["modifyvm", :id, "--cpus", "1"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
  end
end
