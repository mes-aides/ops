#!/bin/bash

set +ev

cd
ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -m PEM -N "" -C "contact@mes-aides.gouv.fr"
apt-get install --assume-yes python3-pip vim
mkdir --parents /opt/mes-aides
rsync -r /vagrant/ /opt/mes-aides/ops
cd /opt/mes-aides/ops
pip3 install --requirement requirements.txt
cat "$HOME/.ssh/id_rsa.pub" >>  "$HOME/.ssh/authorized_keys"
fab bootstrap --host localhost --name vagrant-local. --dns-ok
