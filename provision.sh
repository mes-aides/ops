#!/bin/bash

cd $(dirname "$BASH_SOURCE")
set -ev

export PATH=/opt/puppetlabs/bin:$PATH
puppet apply ../bootstrap/manifests/ops.pp --verbose --modulepath=../bootstrap/modules
/opt/mes-aides/ops/deploy.sh
