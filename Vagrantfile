# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
#

Vagrant.configure(2) do |config|
  config.vm.box = "puppetlabs/centos-7.0-64-puppet"


  config.vm.network "private_network", ip: "192.168.67.12", auto_config: false

   config.vm.provision "shell", inline: <<-END_SHELL
     
     ## Configure some scaffolding and run the vagrant.pp from the module 
     sudo ln -s /vagrant /etc/puppetlabs/code/environments/production/modules/network_config
     puppet module install puppetlabs/stdlib
     puppet module install puppetlabs/inifile
     puppet module install crayfishx/purge
     
  END_SHELL
end
