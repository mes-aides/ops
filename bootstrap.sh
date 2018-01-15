#!/bin/bash

cd $(dirname "$BASH_SOURCE")

set -ev

LATEST_PUPPET_PACKAGE=puppetlabs-release-pc1-trusty.deb

PROVISIONING_FOLDER=/opt/mes-aides
BOOTSTRAP_FOLDER=$PROVISIONING_FOLDER/bootstrap
BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER=$BOOTSTRAP_FOLDER/manifests
OPS_FOLDER=$PROVISIONING_FOLDER/ops
MANIFESTS_SOURCE_FOLDER=manifests
MANIFESTS_SOURCE_REPOSITORY=betagouv/mes-aides-ops


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

# Required because of https://tickets.puppetlabs.com/browse/PUP-2754
function run_puppet {
    set +e
    puppet apply --detailed-exitcodes --verbose "$@"
    exit_code=$?
    set -e
    [[ $exit_code = 0  ]] || [[ $exit_code = 2 ]]
}

install_manifest bootstrap
install_manifest ops

# Define repository revisions
echo ${1:-origin/master} > $PROVISIONING_FOLDER/ui_target_revision
echo ${2:-origin/master} > $PROVISIONING_FOLDER/ops_target_revision

# One off script that will
# * install librarian-puppet in Puppet internal ruby to download Puppet modules
# * download a bootstrap Puppetfile
# * download specified modules
run_puppet $BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER/bootstrap.pp --modulepath=modules

# Script to run on mes-aides-ops update
# * update local mes-aides-ops repository
# * download modules
run_puppet $BOOTSTRAP_MANIFESTS_DESTINATION_FOLDER/ops.pp --modulepath=$BOOTSTRAP_FOLDER/modules

# Script to run on mes-aides-ui update
# * update local mes-aides-ui
# * set up the full mes-aides stack
run_puppet $OPS_FOLDER/manifests/default.pp --modulepath=$OPS_FOLDER/modules
