#!/bin/bash

cd $(dirname "$BASH_SOURCE")
set -ev

export PATH=/opt/puppetlabs/bin:$PATH
puppet apply manifests/default.pp --verbose --modulepath=modules
