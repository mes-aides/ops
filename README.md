# Mes Aides ops

Set up the [Mes Aides](https://mes-aides.org) stack.

> Déploie l'infrastructure de Mes Aides.


## Initial provisioning

Prerequisite:
- Python 3 and virtualenv
- An SSH connection to the root user of the remote server


```
SERVER=51.91.78.117
NAME=wiru
ssh root@$SERVER -C date

virtualenv .venv37 --python=python3.7
pip install --requirement requirements.txt --upgrade

ssh-add ~/.ssh/id_rsa
fab bootstrap --host $SERVER
fab provision --host $SERVER --name $NAME
# fab provision --host $SERVER --name $NAME --dns-ok
```

## Update production provisioning

```
fab sync --host=mes-aides.org
```

## Rune provisioning from personal computer


cf. files/update.sh and deploy CircleCI workflow in main repository

```
fab refresh --host mes-aides.org
```

### Secret environment variables

The main NodeJS server needs some private variables for production, stored at '/home/main/mes-aides-ui/backend/config/production.js'

These variables can be fetched from the current production server with `fab production-config-get`, _--host_ can be specified but default to _mes-aides.org_. Then the configuration file can be put on another server with `fab production-config-put --host <hostname>`. 


### Continuous deployment

An private key can `ssh` to the host and it will automatically deploy the application latest version.

That private key has been added to CirclecCI (mes-aides-ui repository) to allow continuous deployment.


## Development

Development is done using Vagrant and a Debian 10 (buster).

The `vagrant up` command shoudl give you a VM in a similar environment as OVH **clean** instance.
You have to run provisioning commands to set up the server.


Currently, it gives you:
- A MongoDB instance with default settings.
- Mes Aides on port 8000 (ExpressJS application).
- OpenFisca on port 2000 (Python via gunicorn).
- A basic monitor server

And via nginx :
- the application as a default server and on 4 host names:
    - (www\.)?(<prefix>\.)?mes-aides.org,
- OpenFisca on 2 host names:
    - (openfisca.)?(<prefix>\.)?mes-aides.org,
- the monitor on 2 host names:
    - (monitor.)?(<prefix>\.)?mes-aides.org,

HTTPS (and associated redirection) is setup if Let's Encrypt certificates are availables (3 set of certificates)

# Monitor

Two different scanning services are used, in order to remove dependency on one specific provider to notify in case of a service failure.
This endpoint is scanned by [UptimeRobot](https://uptimerobot.com) on a 1-minute interval, and will notify the team through Slack and SMS. It is also scanned on a 2-minute interval by [SetCronJob](https://www.setcronjob.com) which will notify the team by email. The SetCronJob instance has to be manually rearmed (i.e. re-enabled after it gets automatically disabled on failure) when it has been triggered.
