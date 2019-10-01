#!/bin/bash

set -ev

# Info
pwd
ls -al

apt-get update
apt-get install --assume-yes openssh-client python3-pip rsync vim
mkdir --parents /opt/mes-aides

if [ test -e /vagrant/ ];
then
  rsync -r /vagrant/ /opt/mes-aides/ops
else
  rsync -r . /opt/mes-aides/ops
fi

cd
ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -m PEM -N "" -C "contact@mes-aides.gouv.fr"
cd /opt/mes-aides/ops
pip3 install --requirement requirements.txt
cat "$HOME/.ssh/id_rsa.pub" >>  "$HOME/.ssh/authorized_keys"
fab bootstrap --host localhost --name vagrant-local. --dns-ok
