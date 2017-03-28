#!/bin/bash

cd $(dirname "$BASH_SOURCE")
set -ev

for line in $(echo $SSH_ORIGINAL_COMMAND | sed 's/ /\n/g' | grep -E '^(ui|ops)_head=')
do
    key=$(echo $line|grep -o -E '^[^=]*')
    value=$(echo $line|grep -o -E '[^=]*$')

    tmp_path=/tmp/$key
    echo $value > $tmp_path

    head_path=/opt/mes-aides/$key
    mv --backup --suffix=$(date '+.bck_upto_%Y-%m-%d_%H-%M-%S') $tmp_path $head_path
done

export PATH=/opt/puppetlabs/bin:$PATH
puppet apply ../bootstrap/manifests/ops.pp --verbose --modulepath=../bootstrap/modules
/opt/mes-aides/ops/deploy.sh
