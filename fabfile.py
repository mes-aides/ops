from fabric import task, Connection
from contextlib import contextmanager
from jinja2 import Environment, FileSystemLoader, Template
import os
import requests
import tempfile


SERVER_IP="51.254.223.109"
SERVER_IP="192.168.56.200"
SERVER_IP="54.36.180.23"
USER="root"
WEBROOT_PATH="/var/www"

HOST='vps275796'
HOSTNAME='vps515386.mes-aides.gouv.fr'

loader = Environment(loader=FileSystemLoader('.'))

#vps275796.mes-aides.gouv.fr
# DNSs
# vps275796        3600 IN A      51.254.223.109
# www.vps275796        3600 IN A      51.254.223.109
# openfisca.vps275796        3600 IN A      51.254.223.109
# monitor.vps275796        3600 IN A      51.254.223.109


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
def vagrant(ctx, port, identity):
  c = Connection('127.0.0.1', 'vagrant', port, connect_kwargs={
    "key_filename": identity,
  })
  c.run('hostname')
  ssh_access(ctx, c)

@task
def tell_me_your_name(ctx, host=SERVER_IP):
  c = Connection(host=host, user=USER)
  c.run('hostname')
  c.run('date')
  c.run('uname -a')
  c.run('lsb_release -a')


@task
def bootstrap(ctx, host=SERVER_IP, name=None):
  c = Connection(host=host, user=USER)
  system(c, name)
  nginx_setup(c)
  node(c)
  mongodb(c)

  monitor(c)

  python(c)
  openfisca_setup(c)
  openfisca_config(c)

  nginx_sites(c, 'local', is_default=True)

  app_setup(c)

  refresh_tasks(ctx, c)


@task
def refresh(ctx, host=SERVER_IP):
  c = Connection(host=host, user=USER)
  refresh_tasks(c)


@task
def test(ctx, host=SERVER_IP, name=None):
  c = Connection(host=host, user=USER)
  nginx_sites(c, 'local', is_default=True)


  # c = Connection(host=host, user=USER)

  # name = 'monitor'
  # fullname = '%s..mes-aides.gouv.fr' % (name, HOST)
  # is_default = False
  # add_www_subdomain = False
  # certificate_path = '/etc/letsencrypt/live/%s/fullchain.pem' % fullname
  # c.run('certbot certonly --webroot --non-interactive --cert-name %s -d %s %s --webroot-path %s' % (fullname, fullname, ' --expand -d www.%s' % fullname if add_www_subdomain else'' , WEBROOT_PATH))
  # missing_certificate = c.run('test -e %s' % certificate_path, warn=True).exited
  # main = {
  #   'name': fullname,
  #   'add_www_subdomain': add_www_subdomain,
  #   'is_default': is_default,
  #   'upstream_name' : name,
  #   'nginx_root': '/home/main/mes-aides-ui',
  #   'ssl_exists': not missing_certificate,
  # }
  # with write_nginx_config(main) as fp:
  #   c.put(fp, '/etc/nginx/sites-enabled/%s.conf' % fullname)

  # c.run('service nginx reload')


def refresh_tasks(ctx, c):
  ssh_access(ctx, c)
  app_refresh(c)
  openfisca_refresh(c)

def ssl_setup(c):
  dhparam_path = '/etc/ssl/private/dhparam.pem'
  missing = c.run('test -e %s' % dhparam_path, warn=True).exited
  if missing:
    c.run('/usr/bin/openssl dhparam -out %s 2048' % dhparam_path)


def ssh_access(ctx, c):
  users = ctx.config.get('github', [])
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
  letsencrypt(c)


def letsencrypt(c):
  c.run('apt-get install --assume-yes certbot')
  c.run('certbot register --non-interactive --agree-tos --email contact@mes-aides.gouv.fr')


def nginx_site(c, config):
  fullname = config['name']
  add_www_subdomain = config['add_www_subdomain'] if 'add_www_subdomain' in config else False

  with write_nginx_config(config) as fp:
    c.put(fp, '/etc/nginx/sites-enabled/%s.conf' % fullname)
  c.run('service nginx reload')

  certificate_path = '/etc/letsencrypt/live/%s/fullchain.pem' % fullname
  letsencrypt_args = '--cert-name %s -d %s %s --webroot-path %s' % (fullname, fullname, ' --expand -d www.%s' % fullname if add_www_subdomain else '', WEBROOT_PATH)
  letsencrypt_command = 'certbot certonly --webroot --non-interactive %s' % letsencrypt_args
  letsencrypt = c.run(letsencrypt_command, warn=True)
  if letsencrypt.exited:
    print('WARNING Lets encrypt failed')
    print(letsencrypt.stdout)
    print(letsencrypt.stderr)
    print(letsencrypt)
  missing_certificate = c.run('test -e %s' % certificate_path, warn=True).exited

  with write_nginx_config({'ssl_exists': not missing_certificate, **config}) as fp:
    c.put(fp, '/etc/nginx/sites-enabled/%s.conf' % fullname)
  c.run('service nginx reload')


def nginx_sites(c, fullname, is_default=False):
  monitor = {
    'name': 'monitor.%s' % fullname,
    'upstream_name' : 'monitor',
  }
  nginx_site(c, monitor)

  main = {
    'name': fullname,
    'add_www_subdomain': True,
    'is_default': is_default,
    'upstream_name' : 'mes_aides',
    'nginx_root': '/home/main/mes-aides-ui',
  }
  nginx_site(c, main)

  openfisca = {
    'name': 'openfisca.%s' % fullname,
    'upstream_name' : 'openfisca',
  }
  nginx_site(c, openfisca)

  c.run('service nginx reload')


def system(c, name=None):
  if name:
    c.run('hostname %s' % name)
  c.run('apt-get install --assume-yes curl') # curl=7.52.1-5+deb9u9 may be necessary as Curl versions may conflict
  c.run('apt-get install --assume-yes build-essential git man')
  usermain(c)


def usermain(c):
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
  c.run('su - main -c "cd mes-aides-ui && PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1 npm ci"')
  c.run('su - main -c "cd mes-aides-ui && npm run prestart"')
  c.run('su - main -c "cd mes-aides-ui && CHROME_DEVEL_SANDBOX=/usr/local/sbin/chrome-devel-sandbox pm2 startOrReload /home/main/mes-aides-ui/pm2_config.yaml --update-env"')


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
