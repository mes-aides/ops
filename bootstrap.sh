#!/bin/bash

cd $(dirname "$BASH_SOURCE")

set -ev

LATEST_PUPPET_PACKAGE=puppetlabs-release-pc1-trusty.deb

PROVISIONING_FOLDER=/opt/mes-aides
BOOTSTRAP_FOLDER=$PROVISIONING_FOLDER/bootstrap
BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER=$BOOTSTRAP_FOLDER/manifests
OPS_FOLDER=$PROVISIONING_FOLDER/ops
MANIFESTS_SOURCE_FOLDER=manifests
MANIFESTS_SOURCE_REPOSITORY=sgmap/mes-aides-ops


curl --location --remote-name https://apt.puppetlabs.com/$LATEST_PUPPET_PACKAGE
dpkg --install $LATEST_PUPPET_PACKAGE
apt-get update
apt-get --assume-yes install puppet-agent
export PATH=/opt/puppetlabs/bin:$PATH

# Install a manifest file in the manifests folder.
# If a local version is present, it will be used. Otherwise, it will be fetched from the source repository.
install_manifest() {  # $1 = name of the manifest file
    mkdir --parents $BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER

    cp -f ./$MANIFESTS_SOURCE_FOLDER/$1.pp $BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER ||
    curl --location --remote-name https://raw.githubusercontent.com/$MANIFESTS_SOURCE_REPOSITORY/$MANIFESTS_SOURCE_FOLDER/$1.pp --output $BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER
}

install_manifest bootstrap
install_manifest ops


# Define repository revisions
ui_head=origin/master
ops_head=origin/master

if [ $# -gt 0 ]
then
    ui_head=$1
fi

if [ $# -gt 1 ]
then
    ops_head=$2
fi

echo $ui_head > /opt/mes-aides/ui_head
echo $ops_head > /opt/mes-aides/ops_head

# One off script that will
# * install librarian-puppet in Puppet internal ruby to download Puppet modules
# * download a bootstrap Puppetfile
# * download specified modules
puppet apply $BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER/bootstrap.pp --verbose --modulepath=modules

# Script to run on mes-aides-ops update
# * update local mes-aides-ops repository
# * download modules
puppet apply $BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER/ops.pp --verbose --modulepath=$BOOTSTRAP_FOLDER/modules

# Script to run on mes-aides-ui update
# * update local mes-aides-ui
# * set up the full mes-aides stack
puppet apply $OPS_FOLDER/manifests/default.pp --verbose --modulepath=$OPS_FOLDER/modules
