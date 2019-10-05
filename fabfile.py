from fabric import task, Connection
from contextlib import contextmanager
from jinja2 import Environment, FileSystemLoader, Template
import os
import requests
import tempfile

SERVER_IP="54.36.180.23"
HOSTPREFIX='vps515386.'

USER="root"
WEBROOT_PATH="/var/www"

loader = Environment(loader=FileSystemLoader('.'))


@contextmanager
def write_template(path, ctx):
  fp = tempfile.TemporaryFile(mode='w+', encoding='utf8')
  t = loader.get_template(path)
  t.stream(**ctx).dump(fp)
  fp.seek(0)
  yield fp
  fp.close()


@contextmanager
def write_nginx_config(config0):
  config = {
    **config0,
    'webroot_path': WEBROOT_PATH,
  }
  with write_template('files/nginx_config.template', config) as fp:
    yield fp


@task
def vagrant_access(ctx, port, identity):
  c = Connection('127.0.0.1', 'vagrant', port, connect_kwargs={
    "key_filename": identity,
  })
  c.config = ctx.config
  c.run('hostname')
  ssh_access(c)


@task
def tell_me_your_name(c, host=SERVER_IP):
  c = Connection(host=host, user=USER)
  c.run('hostname')
  c.run('date')
  c.run('uname -a')
  c.run('lsb_release -a')


@task
def provision(ctx, host, name, dns_ok=False):
  if not dns_ok:
    print_dns_records(host, name)
    return

  c = Connection(host=host, user=USER)
  c.config = ctx.config
  provision_tasks(c, host, name)


def provision_tasks(c, host, name):
  fullname = '%smes-aides.gouv.fr' % name

  system(c, fullname)
  nginx_setup(c)
  node(c)
  mongodb(c)

  monitor(c)

  python(c)
  openfisca_setup(c)
  openfisca_config(c)

  app_setup(c)

  letsencrypt(c)
  nginx_all_sites(c, fullname)

  refresh_tasks(c)


@task
def proxy_challenge(ctx, host, name, challenge_proxy):
  c = Connection(host=host, user=USER)
  fullname = '%smes-aides.gouv.fr' % name
  nginx_all_sites(c, fullname, challenge_proxy=challenge_proxy)


@task
def regenerate_nginx_hosts(ctx, host):
  c = Connection(host=host, user=USER)
  fullname = c.run('hostname').stdout.split()[0]
  print(fullname)
  nginx_all_sites(c, fullname)

@task
def nginx(ctx, host):
  c = Connection(host=host, user=USER)
  c.run('service nginx status', warn=True)
  c.run('service nginx restart', warn=True)
  c.run('service nginx status')


def print_dns_records(host, name):
  print('DNS records should be updated')
  print('\n'.join(['%s 3600 IN A %s' % (item.ljust(25), host) for item in ['%s%s' % (prefix, name) for prefix in ['', 'www.', 'openfisca.', 'monitor.']]]))
  print('Once it is done add --dns-ok')


@task
def refresh(ctx, host=SERVER_IP):
  c = Connection(host=host, user=USER)
  c.config = ctx.config
  refresh_tasks(c)


@task
def fallback(ctx, host=SERVER_IP, name=None):
  c = Connection(host=host, user=USER)


def refresh_tasks(c):
  ssh_access(c)
  app_refresh(c)
  openfisca_refresh(c)


def ssl_setup(c):
  dhparam_path = '/etc/ssl/private/dhparam.pem'
  missing = c.run('test -e %s' % dhparam_path, warn=True).exited
  if missing:
    c.run('/usr/bin/openssl dhparam -out %s 2048' % dhparam_path)


def ssh_access(c):
  users = c.config.get('github', [])
  assert users.length, "Attention, aucun utilisateur github spécifié, risque d'être bloqué hors du serveur !"
  conf = {
    'users': [{ 'name': u, 'ssh_keys': requests.get("https://github.com/%s.keys" % u).text} for u in users]
  }
  with write_template('files/root_authorized_keys.template', conf) as fp:
    c.put(fp, 'authorized_keys')
  c.sudo('mkdir --parents /root/.ssh')
  c.sudo('mv authorized_keys /root/.ssh/authorized_keys')
  c.sudo('chmod 600 /root/.ssh/authorized_keys')
  c.sudo('chown root:root /root/.ssh/authorized_keys')


def nginx_setup(c):
  c.run('apt-get install --assume-yes nginx')
  c.put('files/nginx.ssl_params.conf', '/etc/nginx/snippets/ssl_params.conf')
  c.put('files/nginx.upstreams.conf', '/etc/nginx/conf.d/upstreams.conf')
  c.put('files/nginx_mesaides_static.conf', '/etc/nginx/snippets/mes-aides-static.conf')

  c.run('rm -f /etc/nginx/sites-enabled/default')
  c.run('service nginx reload')
  c.run('mkdir --parents %s' % WEBROOT_PATH)

  ssl_setup(c)


def letsencrypt(c):
  c.run('apt-get install --assume-yes certbot')
  c.run('certbot register --non-interactive --agree-tos --email contact@mes-aides.gouv.fr')


def nginx_site(c, config):
  fullname = config['name']
  add_www_subdomain = config['add_www_subdomain'] if 'add_www_subdomain' in config else False

  ssl_exists = True
  certificate_path = '/etc/letsencrypt/live/%s/fullchain.pem' % fullname
  missing_certificate = c.run('test -e %s' % certificate_path, warn=True).exited
  if missing_certificate:
    with write_nginx_config(config) as fp:
      c.put(fp, '/etc/nginx/sites-enabled/%s.conf' % fullname)
    c.run('service nginx reload')

    letsencrypt_args = '--cert-name %s -d %s %s --webroot-path %s' % (fullname, fullname, ' --expand -d www.%s' % fullname if add_www_subdomain else '', WEBROOT_PATH)
    letsencrypt_command = 'certbot certonly --webroot --non-interactive %s' % letsencrypt_args
    letsencrypt = c.run(letsencrypt_command, warn=True)
    if letsencrypt.exited:
      print('WARNING Lets encrypt failed')
      print(letsencrypt.stdout)
      print(letsencrypt.stderr)
      print(letsencrypt)
      ssl_exists = False

  with write_nginx_config({'ssl_exists': ssl_exists, **config}) as fp:
    c.put(fp, '/etc/nginx/sites-enabled/%s.conf' % fullname)
  c.run('service nginx reload')


def nginx_sites(c, fullname, is_default=False, challenge_proxy=None):
  monitor = {
    'name': 'monitor.%s' % fullname,
    'upstream_name' : 'monitor',
    'challenge_proxy': challenge_proxy
  }
  nginx_site(c, monitor)

  main = {
    'name': fullname,
    'add_www_subdomain': True,
    'is_default': is_default,
    'upstream_name' : 'mes_aides',
    'nginx_root': '/home/main/mes-aides-ui',
    'challenge_proxy': challenge_proxy,
  }
  nginx_site(c, main)

  openfisca = {
    'name': 'openfisca.%s' % fullname,
    'upstream_name' : 'openfisca',
    'challenge_proxy': challenge_proxy,
  }
  nginx_site(c, openfisca)

  c.run('service nginx reload')


def nginx_all_sites(c, fullname, challenge_proxy=None):
  nginx_sites(c, fullname, is_default=False, challenge_proxy=challenge_proxy)
  nginx_sites(c, 'mes-aides.gouv.fr', is_default=True, challenge_proxy=challenge_proxy)


def system(c, name=None):
  if name:
    c.run('hostname %s' % name)
  c.run('apt-get install --assume-yes curl') # curl=7.52.1-5+deb9u9 may be necessary as Curl versions may conflict
  c.run('apt-get install --assume-yes build-essential git man vim')

  c.run('apt-get install --assume-yes chromium')
  c.run('sysctl -w kernel.unprivileged_userns_clone=1')
  usermain(c)


def usermain(c):
  missing = c.run('id -u main', warn=True).exited
  if missing:
    c.run('useradd main --create-home --shell /bin/bash')


def node(c):
  c.run('curl --silent --location https://deb.nodesource.com/setup_12.x | bash -')
  c.run('apt-get install --assume-yes nodejs')
  pm2(c)


def pm2(c):
  c.run('npm install --global pm2@3.5.1')
  c.run('pm2 startup systemd -u main --hp /home/main')


def python(c):
  c.run('apt-get install --assume-yes python3.7 python3.7-dev python3-venv')


# https://linuxhint.com/install_mongodb_debian_10/
def mongodb(c):
  result = c.run('apt-key list', hide=True)
  if True or 'Mongo' not in result.stdout:
    c.run('apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4')
    c.run('echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" | tee /etc/apt/sources.list.d/mongodb-org.list')
    c.run('echo "deb http://deb.debian.org/debian/ stretch main" | tee /etc/apt/sources.list.d/debian-stretch.list')
    c.run('apt update')
  else:
    print('MongoDB packages already setup')
  c.run('apt-get install --assume-yes libcurl3')
  c.run('apt-get install --assume-yes mongodb-org')
  c.run('service mongod start')
  c.run('systemctl enable mongod')


def monitor(c):
  c.run('mkdir --parents /opt/mes-aides')
  c.put('files/monitor/monitor.sh', '/opt/mes-aides/monitor.sh')
  c.put('files/monitor/monitor-server.js', '/opt/mes-aides/monitor-server.js')
  c.put('files/monitor/ma-monitor.service', '/etc/systemd/system/ma-monitor.service')
  c.run('systemctl daemon-reload')
  c.run('service ma-monitor restart')
  c.run('systemctl enable ma-monitor')


def app_setup(c):
  c.run('su - main -c "git clone https://github.com/betagouv/mes-aides-ui.git"')
  production_path = '/home/main/mes-aides-ui/backend/config/production.js'
  result = c.run('[ -f %s ]' % production_path, warn=True)
  if result.exited:
    c.run('su - main -c "cp /home/main/mes-aides-ui/backend/config/continuous_integration.js %s"' % production_path)
  test = c.run('su - main -c "crontab -l 2>/dev/null | grep -q \'backend/lib/stats\'"', warn=True)
  if test.exited:
    c.run('su - main -c \'(crontab -l 2>/dev/null; echo "23 2 * * * /usr/bin/node /home/main/mes-aides-ui/backend/lib/stats") | crontab -\'')


def app_refresh(c):
  c.run('su - main -c "cd mes-aides-ui && git pull"')
  c.run('su - main -c "cd mes-aides-ui && npm ci"')
  c.run('su - main -c "cd mes-aides-ui && npm run prestart"')
  c.run('su - main -c "cd mes-aides-ui && pm2 startOrReload /home/main/mes-aides-ui/pm2_config.yaml --update-env"')


venv_dir = '/home/main/venv_python3.7'
def openfisca_setup(c):
  c.run('su - main -c "python3.7 -m venv %s"' % venv_dir)


def openfisca_config(c):
  with write_template('files/openfisca.service.template', { 'venv_dir': venv_dir }) as fp:
    c.put(fp, '/etc/systemd/system/openfisca.service')
  c.run('systemctl daemon-reload')
  c.run('service openfisca restart')
  c.run('systemctl enable openfisca')


def openfisca_refresh(c):
  c.run('su - main -c "%s/bin/pip3 install --upgrade pip"' % venv_dir)
  c.run('su - main -c "cd mes-aides-ui && %s/bin/pip3 install --upgrade -r openfisca/requirements.txt"' % venv_dir)
  c.run('service openfisca restart')
