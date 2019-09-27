from fabric import task, Connection
from contextlib import contextmanager
from jinja2 import Environment, FileSystemLoader, Template
import os
import tempfile


SERVER_IP = "51.254.223.109"
USER="root"

loader = Environment(loader=FileSystemLoader('.'))


@contextmanager
def write(path, ctx):
  fp = tempfile.TemporaryFile(mode='w+', encoding='utf8')
  t = loader.get_template(path)
  t.stream(**ctx).dump(fp)
  fp.seek(0)
  yield fp
  fp.close()


@task
def tell_me_your_name(c, file='ok'):
  print(file)
  cc = Connection(host=SERVER_IP, user=USER)
  cc.run('hostname')
  cc.run('date')
  cc.run('uname -a')
  cc.run('lsb_release -a')
  cc.put('test', remote='/root/test')
  cc.run('cat /root/test')
  with write('test', {'name': 'Dan'}) as fp:
    cc.put(fp, '/root/template')
  cc.run('cat /root/template')


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


def nginx(c):
  c.run('apt-get install --assume-yes nginx')


def system(c):
  c.run('apt-get install --assume-yes curl man')


def node(c):
  c.run('curl --silent --location https://deb.nodesource.com/setup_12.x | bash -')
  c.run('apt-get install --assume-yes nodejs')


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
