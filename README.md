# Mes Aides ops

Set up the [Mes Aides](https://mes-aides.gouv.fr) stack.

> Déploie l'infrastructure de Mes Aides.


## Limitations

* Provisioning only possible on Ubuntu 14.04 (trusty)
* NodeJS 0.10 installation is **distribution dependant** (because of *0.10.48-1nodesource1~trusty1*)


## Initial provisioning

The following commands run as **root** in the destination machine sets the [Mes Aides](https://mes-aides.gouv.fr) stack up.

```
BRANCH_NAME=master
curl --location --remote-name https://github.com/sgmap/mes-aides-ops/archive/$BRANCH_NAME.tar.gz
tar -xvf $BRANCH_NAME.tar.gz
cd mes-aides-ops-$BRANCH_NAME
./bootstrap.sh origin/master origin/$BRANCH_NAME
```

`./bootstrap.sh origin/master origin/$BRANCH_NAME` initiates the set-up. By default, `origin/master` is used for both repositories (https://github.com/sgmap/mes-aides-ui and https://github.com/sgmap/mes-aides-ops). That can be overidden by passing *TREEISH* parameters. The first one is the target revision for `mes-aides-ui`and the second one is the target revision for `mes-aides-ops`.

That is why the suggested set of commands above overrides the default target revision of `mes-aides-ops` to rely on the selected branch.


### HTTPS configuration

Limitation: The initial setup can't be done with HTTPS enabled because NGINX has to be properly configured on port 80 before requesting an SSL certificate.

An HTTPS configuration is enabled if the file `/opt/mes-aides/use_ssl` exists (you can create it with `sudo touch /opt/mes-aides/use_ssl`).


## Continuous provisioning and deployment

### Provisioning

A private key has been generated so that one can `ssh` to the host and it will automatically trigger:
- `puppet apply ops.pp` (update of mes-aides-ops on the host)
- `puppet apply default.pp` (host provisioning with mes-aides-ui deployment)

That private key has been added to CircleCI (mes-aides-ops repository) to allow continuous provisioning.


### Deployment

Another private key can `ssh` to the host and it will automatically run `puppet apply default.pp` (host provisioning with mes-aides-ui deployment).

That private key has been added to CirclecCI (mes-aides-ui repository) to allow continuous deployment.


## Branch/SHA1 live deployment

Branch specifications are expected to be done during the initial provisioning as described in the above section. However, revisions can be directly updated on the server. The following script updates mes-aides-ui target revision to `origin/staging` and triggers a redeployment. A similar script could be created to provision the server using a different target revision than `origin/master`.

```shell
UI_TARGET_REVISION=origin/staging
echo $UI_TARGET_REVISION > /opt/mes-aides/ui_target_revision
/opt/mes-aides/update.sh deploy
```


## Development

Development is done using Vagrant and the Ubuntu version used in production: Ubuntu 14.04 64 bit (trusty).

The `vagrant up` command should give you a fully functioning Mes Aides instance.

Currently, it gives you:

- A MongoDB instance with default settings.
- Mes Aides on port 8000 (ExpressJS application).
- OpenFisca on port 2000 (Python via gunicorn).

And then:

- Mes Aides on port 80 thanks to NGINX proxy.

or

- A redirection from port 80 to https://vps.mes-aides.gouv.fr
- Mes Aides on port 433 at hostname vps.mes-aides.gouv.fr


### Iterations

By default, the guest instance is available at `192.168.56.100`. The Vagrantfile is set up to make iterations relatively easy. If your repository is checked out in a directory named `n(_label)` where `n` is a number, the guest instance will be available at `192.168.56.(100+n)`.


## Details

Currently, applications are set up and run by *ubuntu* user.


## TODO

- Check relative path possibilities
    + vcsrepo { '/home/ubuntu/mes-aides-ui':
        * /opt alternatives
        * Absolute paths are required in vcsrepo https://github.com/puppetlabs/puppetlabs-vcsrepo/blob/master/lib/puppet/type/vcsrepo.rb#L162
    + exec { 'install node modules for mes-aides-ui':
        * absolute or qualified with path https://docs.puppet.com/puppet/latest/types/exec.html#exec-attribute-command
- Can we use the user running puppet --apply?
    + Yes we can and rely on facts "${facts['identity']['user']}"
    + To prevent explicit user reference
    + exec { 'install node modules for mes-aides-ui':
- Comment current Python setup (python:requirements do not accept --upgrade)
- Surcouche service/upstart
- Move inline shell scripts to files
    + bootstrap.sh
- Create CI deployment script
    + Add in Circle CI in production
- Formal test of CI deployment
- Add Let's Encrypt SSL support (OPT IN for SSL)
    + Rely on mes-aides.gouv.fr certificate
    + Prevent renewal
- Create OpenFisca Puppet module?
- Create Mes-Aides Puppet module (to make feature branch deployment a breeze)?


# Monitor

Two different scanning services are used, in order to remove dependency on one specific provider to notify in case of a service failure.
This endpoint is scanned by [UptimeRobot](https://uptimerobot.com) on a 1-minute interval, and will notify the team through Slack and SMS. It is also scanned on a 2-minute interval by [SetCronJob](https://www.setcronjob.com) which will notify the team by email. The SetCronJob instance has to be manually rearmed (i.e. re-enabled after it gets automatically disabled on failure) when it has been triggered.
