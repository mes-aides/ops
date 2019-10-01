#!/bin/bash

set -ev

CIRCLE_SHA1=0e3fe3ce87d8edb6295e28fccc0f2265089b4b51
NAME=vagrant-local.

wget --retry-connrefused --tries=10 -O /tmp/artifacts/node.out 0.0.0.0:8000 2>/tmp/artifacts/wget.log
cat /tmp/artifacts/node.out | grep --silent 'mes-aides.gouv.fr'
wget --retry-connrefused --tries=10 -O /tmp/artifacts/nginx.out 0.0.0.0 2>/tmp/artifacts/wget.log
wget 0.0.0.0/fonts/fontawesome-webfont.woff --quiet --spider --server-response 2>&1 | grep --silent "HTTP/1.1 200 OK"
cat /tmp/artifacts/nginx.out | grep --silent 'mes-aides.gouv.fr'
wget --quiet --output-document=- 0.0.0.0:2000/variable/parisien 2>&1 | grep --silent openfisca_paris/paris.py

wget --quiet --header "Host: openfisca.${NAME}mes-aides.gouv.fr" --output-document=- 0.0.0.0/variable/parisien | grep --silent openfisca_paris/paris.py
wget --quiet --header "Host: monitor.${NAME}mes-aides.gouv.fr" --content-on-error --output-document=- 0.0.0.0 | grep --silent $CIRCLE_SHA1

systemctl status openfisca --lines=0 > /tmp/artifacts/openfisca-service.start.txt
grep 'Main PID' /tmp/artifacts/openfisca-service.start.txt > /tmp/artifacts/openfisca-service-pid.start.txt

systemctl status openfisca --lines=0 > /tmp/artifacts/openfisca-service.post-provision.txt
grep 'Main PID' /tmp/artifacts/openfisca-service.post-provision.txt > /tmp/artifacts/openfisca-service-pid.post-provision.txt
diff /tmp/artifacts/openfisca-service-pid.post-provision.txt /tmp/artifacts/openfisca-service-pid.start.txt

systemctl status openfisca --lines=0 > /tmp/artifacts/openfisca-service.post-deploy.txt
grep 'Main PID' /tmp/artifacts/openfisca-service.post-deploy.txt > /tmp/artifacts/openfisca-service-pid.post-deploy.txt
diff /tmp/artifacts/openfisca-service-pid.post-deploy.txt /tmp/artifacts/openfisca-service-pid.start.txt
