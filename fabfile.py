from fabric import task, Connection
from contextlib import contextmanager
from jinja2 import Environment, FileSystemLoader, Template
import os
import tempfile


SERVER_IP = "51.254.223.109"
USER="root"

loader = Environment(loader=FileSystemLoader('.'))


@contextmanager
def write_template(path, ctx):
  fp = tempfile.TemporaryFile(mode='w+', encoding='utf8')
  t = loader.get_template(path)
  t.stream(**ctx).dump(fp)
  fp.seek(0)
  yield fp
  fp.close()


@task
def tell_me_your_name(c):
  cc = Connection(host=SERVER_IP, user=USER)
  cc.run('hostname')
  cc.run('date')
  cc.run('uname -a')
  cc.run('lsb_release -a')


@task
def bootstrap(c):
  cc = Connection(host=SERVER_IP, user=USER)
  system(cc)
  nginx(cc)
  node(cc)
  python(cc)
  mongodb(c)


@task
def test(ctx):
  c = Connection(host=SERVER_IP, user=USER)
  monitor(c)


def nginx(c):
  c.run('apt-get install --assume-yes nginx')
  c.put('files/nginx.upstreams.conf', '/etc/nginx/conf.d/upstreams.conf')
  c.run('rm -f /etc/nginx/sites-enabled/default')
  c.run('service nginx reload')


def system(c):
  c.run('apt-get install --assume-yes curl=7.52.1-5+deb9u9') # Curl versions conflict
  c.run('apt-get install --assume-yes man')
  usermain(c)


def usermain(c):
  c.run('useradd main --create-home')


def node(c):
  c.run('curl --silent --location https://deb.nodesource.com/setup_12.x | bash -')
  c.run('apt-get install --assume-yes nodejs')
  pm2(c)


def pm2(c):
  #c.run('npm install --global pm2@3.5.1')
  c.run('pm2 startup systemd')


def python(c):
  c.run('apt-get install --assume-yes python3.7 python3.7-dev python3.7-venv')


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


def monitor(c):
  c.run('mkdir --parents /opt/mes-aides')
  c.put('files/monitor/monitor.sh', '/opt/mes-aides/monitor.sh')
  c.put('files/monitor/monitor-server.js', '/opt/mes-aides/monitor-server.js')
  c.put('files/monitor/ma-monitor.service', '/etc/systemd/system/ma-monitor.service')
  c.run('systemctl daemon-reload')
  c.run('service ma-monitor restart')
  c.run('systemctl enable ma-monitor')
  monitor = {
    'name': 'monitor.mes-aides.gouv.fr',
    'upstream_name' : 'monitor',
    'webroot_path': '/var/www/',
  }
  with write_template('files/nginx_config.template', monitor) as fp:
    c.put(fp, '/etc/nginx/sites-enabled/monitor.mes-aides.gouv.fr.conf')
  c.run('service nginx reload')
