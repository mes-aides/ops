#!/bin/bash

cd $(dirname "$BASH_SOURCE")

set -ev

# Update puppet to version >= 3.2.2 before using puppet provisioning.
wget https://apt.puppetlabs.com/puppetlabs-release-pc1-trusty.deb
dpkg -i puppetlabs-release-pc1-trusty.deb
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
        wget --output-document=$DIRECTORY/$REPO_PATH https://raw.githubusercontent.com/sgmap/mes-aides-ops/master/$REPO_PATH
    fi
done

puppet apply /opt/mes-aides-bootstrap/manifests/bootstrap.pp --verbose --modulepath=modules
puppet apply /opt/mes-aides-bootstrap/manifests/ops.pp --verbose --modulepath=/opt/mes-aides-bootstrap/modules
puppet apply /opt/mes-aides-ops/manifests/default.pp --verbose --modulepath=/opt/mes-aides-ops/modules
