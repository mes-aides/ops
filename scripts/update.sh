#!/bin/bash
# MANAGED BY MES AIDES OPS

set -e

echo "Your SSH connection triggered a shell script ($0 $@)."
if [ ! -z $1 ] && [ ! -z $2 ]; then
    cd /opt/mes-aides/
    ansible-playbook -v \
        --inventory "inventories/$1.yaml" \
        --extra-vars "target_application=$2" \
        --tags="update" \
        --connection=local \
        bootstrap.yaml
    exit 1
fi
