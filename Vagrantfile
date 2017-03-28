# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"

  # Guest have 500MB of RAM by default
  # That is not enough to `npm install`
  # Upgrading to 3GB
  config.vm.provider :virtualbox do |vb|
    vb.memory = 3072
  end

  # Allow development on various version relatively simply
  current_directory = Dir.pwd.split("/").last
  delimiter = current_directory.index("_")
  current_index = 100 + (delimiter ? current_directory[0..(delimiter - 1)].to_i : 0)
  current_private_ip = "192.168.56.#{current_index}"

  puts "This instance will be reachable at #{current_private_ip}"
  config.vm.define "mes_aides_#{current_directory}"
  config.vm.network "private_network", ip: current_private_ip

  head_commit_hash = `cat .git/$(git symbolic-ref HEAD)`
  config.vm.provision :shell, inline: "/vagrant/bootstrap.sh origin/master #{head_commit_hash}"
end
