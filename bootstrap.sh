#!/bin/bash

cd $(dirname "$BASH_SOURCE")

set -ev

# Update puppet to version >= 3.2.2 before using puppet provisioning.
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-trusty.deb
dpkg -i puppetlabs-release-pc1-trusty.deb
apt-get update
apt-get -y install puppet-agent
export PATH=/opt/puppetlabs/bin:$PATH

cp -f Puppetfile /opt/puppetlabs/puppet/Puppetfile

cd /opt/puppetlabs/puppet/
gem install librarian-puppet
librarian-puppet install

cd -
cp -r modules/mesaides /opt/puppetlabs/puppet/modules/
/opt/puppetlabs/bin/puppet apply manifests/default.pp --verbose --modulepath=/opt/puppetlabs/puppet/modules
