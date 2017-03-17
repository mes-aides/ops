# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = 'ubuntu/trusty64'

  # Guest have 500MB of RAM by default
  # That is not enough to `npm install`
  # Upgrading to 3GB
  config.vm.provider :virtualbox do |vb|
    vb.memory = 3072
  end

  # Allow development on various version relatively simply
  current_directory = Dir.pwd.split('/').last
  current_index = 100 + current_directory[0..(current_directory.index('_')-1)].to_i
  current_private_ip = '192.168.56.' + current_index.to_s

  print('This instance will be reachable at ' + current_private_ip + "\n")
  config.vm.define 'mes_aides_' + current_directory
  config.vm.network 'private_network', ip: current_private_ip

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
  cd /opt/puppetlabs/puppet/
  cp /vagrant/Puppetfile /opt/puppetlabs/puppet/Puppetfile
  librarian-puppet install
  cp -r /vagrant/modules/mesaides /opt/puppetlabs/puppet/modules/
  /opt/puppetlabs/bin/puppet apply /vagrant/manifests/default.pp --verbose --modulepath=/opt/puppetlabs/puppet/modules
SCRIPT
  config.vm.provision :shell, :inline => $puppet_provisioning_script
end
