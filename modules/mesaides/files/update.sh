#!/bin/bash
# Managed by puppet from automation_script.sh 

set -e

MES_AIDES_ROOT=/opt/mes-aides/ops

export PATH=/opt/puppetlabs/bin:$PATH

echo "Your SSH connection ($1) triggered a shell script ($0)."
case "$1" in
    provision)
        puppet apply $MES_AIDES_ROOT/manifests/ops.pp --verbose --modulepath=$MES_AIDES_ROOT/modules
        puppet apply $MES_AIDES_ROOT/manifests/default.pp --verbose --modulepath=$MES_AIDES_ROOT/modules
        ;;
    deploy)
        puppet apply $MES_AIDES_ROOT/manifests/default.pp --verbose --modulepath=$MES_AIDES_ROOT/modules
        ;;
    *)
        echo $"Usage: provision|deploy"
        exit 1
esac
