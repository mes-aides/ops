#!/bin/bash

cd $(dirname "$BASH_SOURCE")

set -ev

LATEST_PUPPET_PACKAGE=puppetlabs-release-pc1-trusty.deb

curl --location --remote-name https://apt.puppetlabs.com/$LATEST_PUPPET_PACKAGE
dpkg --install $LATEST_PUPPET_PACKAGE
apt-get update
apt-get --assume-yes install puppet-agent
export PATH=/opt/puppetlabs/bin:$PATH

bootstrap_directory=/opt/mes-aides-bootstrap
mkdir --parents $bootstrap_directory/manifests
for manifest_name in bootstrap ops
do
    path_in_repository=manifests/${manifest_name}.pp
    destination_path=$bootstrap_directory/$path_in_repository
    # Prefer local version over remote
    # It allows a bootstrap installation that differs from master
    # and it fallbacks to a remote file on master
    if [ -e $path_in_repository ]
    then
        cp $path_in_repository $destination_path
    else
        distant_source=https://raw.githubusercontent.com/sgmap/mes-aides-ops/master/$path_in_repository
        curl --location $distant_source --output $destination_path
    fi
done

# One off script that will
# * install librarian-puppet in Puppet internal ruby to download Puppet modules
# * download a bootstrap Puppetfile
# * download specified modules
puppet apply $bootstrap_directory/manifests/bootstrap.pp --verbose --modulepath=modules

# Script to run on mes-aides-ops update
# * update local mes-aides-ops repository
# * download modules
puppet apply $bootstrap_directory/manifests/ops.pp --verbose --modulepath=$bootstrap_directory/modules

# Script to run on mes-aides-ui update
# * update local mes-aides-ui
# * set up the full mes-aides stack
puppet apply /opt/mes-aides-ops/manifests/default.pp --verbose --modulepath=/opt/mes-aides-ops/modules
