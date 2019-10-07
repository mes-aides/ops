#!/bin/bash

set -ev


apt-get update
apt-get install --assume-yes openssh-client python3-pip rsync vim
mkdir --parents /opt/mes-aides
rsync -r /vagrant/ /opt/mes-aides/ops

ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -m PEM -N "" -C "contact@mes-aides.gouv.fr"
cd /opt/mes-aides/ops
pip3 install --requirement requirements.txt
cat "$HOME/.ssh/id_rsa.pub" >>  "$HOME/.ssh/authorized_keys"
fab provision --host localhost --name vagrant-local. --dns-ok
./test.sh
