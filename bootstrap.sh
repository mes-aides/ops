#!/bin/bash

cd $(dirname "$BASH_SOURCE")

set -ev

# Update puppet to version >= 3.2.2 before using puppet provisioning.
package_name=puppetlabs-release-pc1-trusty.deb
# With -r re-downloading a file will result in the new copy simply overwriting the old
curl --location --remote-name https://apt.puppetlabs.com/$package_name
dpkg --install $package_name
apt-get update
apt-get --assume-yes install puppet-agent
export PATH=/opt/puppetlabs/bin:$PATH

DIRECTORY=/opt/mes-aides-bootstrap
mkdir --parents $DIRECTORY/manifests
for element in bootstrap ops
do
    REPO_PATH=manifests/$element.pp
    if [ -e $REPO_PATH ]
    then
        cp $REPO_PATH $DIRECTORY/$REPO_PATH
    else
        curl --location --output $DIRECTORY/$REPO_PATH https://raw.githubusercontent.com/sgmap/mes-aides-ops/master/$REPO_PATH
    fi
done

# One off script that
# * install librarian-puppet in Puppet ruby to download Puppet modules
# * download a bootstrap Puppetfile
# * download specified modules
puppet apply /opt/mes-aides-bootstrap/manifests/bootstrap.pp --verbose --modulepath=modules

# Script to run on mes-aides-ops update
# * update local mes-aides-ops repository
# * download modules
puppet apply /opt/mes-aides-bootstrap/manifests/ops.pp --verbose --modulepath=/opt/mes-aides-bootstrap/modules

# Script to run on mes-aides-ui update
# * update local mes-aides-ui
# * set up the full mes-aides stack
puppet apply /opt/mes-aides-ops/manifests/default.pp --verbose --modulepath=/opt/mes-aides-ops/modules
