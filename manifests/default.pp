
$instance_name = 'metal'

file { '/root/.ssh/authorized_keys':
    content => template('mesaides/root_authorized_keys.erb'),
    ensure  => file,
    group   => 'root',
    mode    => '600',
    owner   => 'root',
}

file { '/opt/mes-aides/update.sh':
    ensure => file,
    group  => 'root',
    mode   => '700',
    owner  => 'root',
    source => 'puppet:///modules/mesaides/update.sh',
}

class { 'nginx': }

include '::mongodb::server'

class { 'nodejs':
    repo_url_suffix => '6.x',
}

package { 'git': }

group { 'main':
    ensure => present,
}

user { 'main':
    ensure     => present,
    managehome => true,
    require    => [ Group['main'] ],
}

vcsrepo { '/home/main/mes-aides-ui':
    ensure   => latest,
    provider => git,
    require    => [ User['main'] ],
    revision => String(file('/opt/mes-aides/ui_target_revision'), "%t"),
    source   => 'https://github.com/betagouv/mes-aides-ui.git',
    user     => 'main',
}

# Using 'make' and 'g++'
package { 'build-essential': }

# Currently required - Failure during npm install
# mes-aides-ui > betagouv-mes-aides-api > ludwig-api > connect-mongo > mongodb > kerberos
package { 'libkrb5-dev': }

exec { 'install node modules for mes-aides-ui':
    command     => '/usr/bin/npm install',
    cwd         => '/home/main/mes-aides-ui',
    environment => ['HOME=/home/main'],
    require     => [ Class['nodejs'], User['main'] ],
    # https://docs.puppet.com/puppet/latest/types/exec.html#exec-attribute-timeout
    #  default is 300 (seconds)
    timeout     => 1800, # 30 minutes
    user        => 'main',
}

exec { 'prestart mes-aides-ui':
    command     => '/usr/bin/npm run prestart',
    cwd         => '/home/main/mes-aides-ui',
    environment => ['HOME=/home/main'],
    notify      => [ Service['openfisca'], Service['ma-web'] ],
    require     => [ Class['nodejs'], Vcsrepo['/home/main/mes-aides-ui'], Exec['install node modules for mes-aides-ui'] ],
    user        => 'main',
}

file { '/etc/init/ma-web.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '644',
    source => 'puppet:///modules/mesaides/ma-web.conf',
}

service { 'ma-web':
    ensure  => 'running',
    require => [ File['/etc/init/ma-web.conf'], User['main'] ],
}

cron { 'refresh mes-aides stats':
    command     => '/usr/bin/node /home/main/mes-aides-ui/backend/lib/stats',
    environment => ['HOME=/home/main'],
    hour        => 2,
    minute      => 23,
    require     => Exec['prestart mes-aides-ui'],
    user        => 'main',
}

::mesaides::nginx_config { 'mes-aides.gouv.fr':
    is_default => true,
    require    => Service['ma-web'],
    use_ssl    => find_file('/opt/mes-aides/use_ssl'),
}

::mesaides::nginx_config { "${instance_name}.mes-aides.gouv.fr":
    require    => Service['ma-web'],
    use_ssl    => find_file("/opt/mes-aides/${instance_name}_use_ssl"),
}

::mesaides::monitor { "monitor.${instance_name}.mes-aides.gouv.fr":
    require => Class['nodejs'],
}

::mesaides::nginx_config { 'monitor.mes-aides.gouv.fr':
    proxied_endpoint => 'http://localhost:8887',
    require    => ::Mesaides::Monitor["monitor.${instance_name}.mes-aides.gouv.fr"],
}

class { 'python':
    dev      => 'present', # default: 'absent'
    # Can't use python gunicorn here as it would be imported from apt instead of pip
    virtualenv => 'present', # default: 'absent'
}

python::virtualenv { '/home/main/venv':
    group        => 'main',
    owner        => 'main',
    require      => [ Class['python'], Vcsrepo['/home/main/mes-aides-ui'], User['main'] ],
}

exec { 'update virtualenv pip':
    command     => '/home/main/venv/bin/pip install pip --upgrade',
    cwd         => '/home/main/mes-aides-ui',
    environment => ['HOME=/home/main'],
    require     => Python::Virtualenv['/home/main/venv'],
    user        => 'main',
}

exec { 'fetch openfisca requirements':
    command     => '/home/main/venv/bin/pip install --upgrade -r openfisca/requirements.txt',
    cwd         => '/home/main/mes-aides-ui',
    environment => ['HOME=/home/main'],
    notify      => [ Service['openfisca'], Service['ma-web'] ],
    require     => [ Exec['update virtualenv pip'], Vcsrepo['/home/main/mes-aides-ui'] ],
    user        => 'main',
}

file { '/etc/init/openfisca.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '644',
    source => 'puppet:///modules/mesaides/openfisca.conf',
}

service { 'openfisca':
    ensure  => 'running',
    require => [ File['/etc/init/openfisca.conf'], User['main'] ],
}

if find_file("/opt/mes-aides/${instance_name}_use_ssl") or find_file('/opt/mes-aides/use_ssl') {
    class { ::letsencrypt:
        config => {
            email => 'contact@mes-aides.gouv.fr',
        }
    }
}
