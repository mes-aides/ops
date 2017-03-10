# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = 'ubuntu/trusty64'
  config.vm.define 'mes_aides'
  config.vm.network 'private_network', ip: '192.168.56.100'

  # Update puppet to version 3.2.2 before using puppet provisioning.
  $puppet_update_script = <<SCRIPT
  wget https://apt.puppetlabs.com/puppetlabs-release-pc1-trusty.deb
  dpkg -i puppetlabs-release-pc1-trusty.deb
  apt-get update
  apt-get -y install puppet-agent
  export PATH=/opt/puppetlabs/bin:$PATH
SCRIPT
  config.vm.provision :shell, :inline => $puppet_update_script

  $librarian_puppet_install_script = <<SCRIPT
  gem install librarian-puppet
SCRIPT
  config.vm.provision :shell, :inline => $librarian_puppet_install_script

  $puppet_provisioning_script = <<SCRIPT
  cd /vagrant
  librarian-puppet install
  /opt/puppetlabs/bin/puppet apply manifests/default.pp --verbose --modulepath=/vagrant/modules
SCRIPT
  config.vm.provision :shell, :inline => $puppet_provisioning_script
end
