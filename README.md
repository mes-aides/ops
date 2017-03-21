# Mes Aides ops

Set up the [Mes Aides](https://mes-aides.gouv.fr) stack.

> Déploie l'infrastructure de Mes Aides.


## Limitations

* Provisioning only possible on Ubuntu 14.04 (trusty)
* NodeJS 0.10 installation is **distribution dependant** (because of *0.10.48-1nodesource1~trusty1*)


## Provisioning

The following commands run as **root** set up the [Mes Aides](https://mes-aides.gouv.fr) stack.

```
curl https://github.com/sgmap/mes-aides-ops/archive/dev.tar.gz
tar -xvf dev.tar.gz
cd mes-aides-ops-dev
./bootstrap.sh
```


## Development

Development is done using Vagrant and the Ubuntu version used in production: Ubuntu 14.04 64 bit (trusty).

The `vagrant up --provider virtualbox` command should give you a fully functioning Mes Aides instance.

Currently, it gives you:

- A MongoDB instance with default settings.
- Mes Aides on port 8000 (ExpressJS application).
- OpenFisca on port 2000 (Python via gunicorn).
- Mes Aides on port 80 thanks to NGINX proxy.


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
