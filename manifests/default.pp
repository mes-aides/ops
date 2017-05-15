file { '/root/.ssh/authorized_keys':
    ensure => file,
    group  => 'root',
    mode   => '600',
    owner  => 'root',
    source => 'puppet:///modules/mesaides/root_authorized_keys',
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
    nodejs_package_ensure => '6.10.3-1nodesource1~trusty1',
    repo_url_suffix => '6.x',
}

include git

vcsrepo { '/home/ubuntu/mes-aides-ui':
    ensure   => latest,
    provider => git,
    revision => String(file('/opt/mes-aides/ui_target_revision'), "%t"),
    source   => 'https://github.com/sgmap/mes-aides-ui.git',
    user     => 'ubuntu',
}

# Using 'make' and 'g++'
package { 'build-essential': }

# Currently required - Failure during npm install
# mes-aides-ui > sgmap-mes-aides-api > ludwig-api > connect-mongo > mongodb > kerberos
package { 'libkrb5-dev': }

exec { 'install node modules for mes-aides-ui':
    command     => '/usr/bin/npm install',
    cwd         => '/home/ubuntu/mes-aides-ui',
    environment => ['HOME=/home/ubuntu'],
    require     => Class['nodejs'],
    # https://docs.puppet.com/puppet/latest/types/exec.html#exec-attribute-timeout
    #  default is 300 (seconds)
    timeout     => 1800, # 30 minutes
    user        => 'ubuntu',
}

exec { 'prestart mes-aides-ui':
    command     => '/usr/bin/npm run prestart',
    cwd         => '/home/ubuntu/mes-aides-ui',
    environment => ['HOME=/home/ubuntu'],
    notify      => [ Service['openfisca'], Service['ma-web'] ],
    require     => [ Class['nodejs'], Vcsrepo['/home/ubuntu/mes-aides-ui'], Exec['install node modules for mes-aides-ui'] ],
    user        => 'ubuntu',
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
    require => File['/etc/init/ma-web.conf'],
}

::mesaides::nginx_config { 'mes-aides.gouv.fr':
    is_default => true,
    require    => Service['ma-web'],
    use_ssl    => find_file('/opt/mes-aides/use_ssl'),
}

::mesaides::nginx_config { 'vps.mes-aides.gouv.fr':
    require    => Service['ma-web'],
    use_ssl    => find_file('/opt/mes-aides/vps_use_ssl'),
}

::mesaides::monitor { 'monitor.vps.mes-aides.gouv.fr':
    require => Class['nodejs'],
}

class { 'python':
    dev      => 'present', # default: 'absent'
    # Can't use python gunicorn here as it would be imported from apt instead of pip
    virtualenv => 'present', # default: 'absent'
}

python::virtualenv { '/home/ubuntu/venv':
    group        => 'ubuntu',
    owner        => 'ubuntu',
    require      => [ Class['python'], Vcsrepo['/home/ubuntu/mes-aides-ui'] ],
}

exec { 'update virtualenv pip':
    command     => '/home/ubuntu/venv/bin/pip install pip --upgrade',
    cwd         => '/home/ubuntu/mes-aides-ui',
    environment => ['HOME=/home/ubuntu'],
    require     => Python::Virtualenv['/home/ubuntu/venv'],
    user        => 'ubuntu',
}

exec { 'fetch openfisca requirements':
    command     => '/home/ubuntu/venv/bin/pip install --upgrade -r openfisca/requirements.txt',
    cwd         => '/home/ubuntu/mes-aides-ui',
    environment => ['HOME=/home/ubuntu'],
    notify      => [ Service['openfisca'], Service['ma-web'] ],
    require     => [ Exec['update virtualenv pip'], Vcsrepo['/home/ubuntu/mes-aides-ui'] ],
    user        => 'ubuntu',
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
    require => File['/etc/init/openfisca.conf'],
}
