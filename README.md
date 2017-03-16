# Mes aides ops

Set up the [Mes Aides](https://mes-aides.gouv.fr) stack.

> Déploie l'infrastructure de Mes Aides.

## Development

Development is done using Vagrant and the Ubuntu version used in production: Ubuntu 14.04 64 bit (trusty).

The ```vagrant up --provider virtualbox``` command should gives you a fully functionning Mes Aides instance.

Currently, it gives you:
- A MongoDB instance with default settings
- Mes-aides on port 8000 (ExpressJS application)
- OpenFisca on port 2000 (Python via gunicorn)
- Mes-aides on port 80 thanks to NGINX proxy

## Limitations

* NodeJS 0.10 installation is **distribution dependant** (because of *0.10.48-1nodesource1~trusty1*)
