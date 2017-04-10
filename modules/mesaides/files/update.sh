#!/bin/bash
# Managed by puppet from modules/mesaides/files/update.sh

set -e

MES_AIDES_ROOT=/opt/mes-aides/ops

function run_puppet {
    set +e
    puppet apply --detailed-exitcodes --verbose $@
    exit_code=$?
    set -e
    [ $exit_code -eq 0  ] || [ $exit_code -eq 2 ]
}

export PATH=/opt/puppetlabs/bin:$PATH

echo "Your SSH connection ($1) triggered a shell script ($0)."
case "$1" in
    provision)
        run_puppet $MES_AIDES_ROOT/manifests/ops.pp --modulepath=$MES_AIDES_ROOT/modules
        run_puppet $MES_AIDES_ROOT/manifests/default.pp --modulepath=$MES_AIDES_ROOT/modules
        ;;
    deploy)
        run_puppet $MES_AIDES_ROOT/manifests/default.pp --modulepath=$MES_AIDES_ROOT/modules
        ;;
    *)
        echo $"Usage: provision|deploy"
        exit 1
esac
