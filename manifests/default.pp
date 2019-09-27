
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

service { 'ssh':
    ensure => 'running',
}

# ^[ ^]* prefix in file_line REGEXes is used to prevent matching on legitimate textual comments
file_line { '/etc/ssh/sshd_config ChallengeResponseAuthentication':
    ensure => present,
    path   => '/etc/ssh/sshd_config',
    line   => 'ChallengeResponseAuthentication no',
    match  => '^[ ^]*ChallengeResponseAuthentication',
    notify => [ Service['ssh'] ],
}

file_line { '/etc/ssh/sshd_config PasswordAuthentication':
    ensure => present,
    path   => '/etc/ssh/sshd_config',
    line   => 'PasswordAuthentication no',
    match  => '^[ ^]*PasswordAuthentication',
    notify => [ Service['ssh'] ],
}

file_line { '/etc/ssh/sshd_config UsePAM':
    ensure => present,
    path   => '/etc/ssh/sshd_config',
    line   => 'UsePAM no',
    match  => '^[ ^]*UsePAM',
    notify => [ Service['ssh'] ],
}

include ntp

class { 'nginx': }

file { '/etc/nginx/snippets':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
}

file { "/etc/nginx/snippets/ssl_params.conf":
    content => template('mesaides/ssl_params.erb'),
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
}

file { "/etc/nginx/snippets/mes-aides-static.conf":
    content => template('mesaides/mesaides_static.erb'),
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '644',
}

file_line { '/etc/nginx/mime.types WOFF':
    ensure  => present,
    path    => '/etc/nginx/mime.types',
    line    => '    application/font-woff                            woff;',
    match   => 'font\/woff.*woff;$',
    require => [ Class['nginx'] ],
}

file_line { '/etc/nginx/mime.types TTF':
    ensure  => 'present',
    path    => '/etc/nginx/mime.types',
    after   => 'application\/font-woff',
    line    => '    font/ttf                                         ttf;',
    require => [ Class['nginx'] ],
}

exec { 'chown pm2 home':
     command => '/bin/chown -R main:main /home/main/.pm2',
     require => [ Exec['install pm2 startup script'] ],
}

service { 'pm2-main':
    ensure  => 'running',
    require => [ Exec['chown pm2 home'] ]
}

file { '/home/main/setup-pm2.sh':
    ensure => file,
    group  => 'main',
    mode   => '700',
    owner  => 'main',
    source => 'puppet:///modules/mesaides/setup-pm2.sh',
    require => [ User['main'] ]
}

exec { 'pm2 install pm2-logrotate':
    command     => '/home/main/setup-pm2.sh /usr/bin/pm2',
    cwd         => '/home/main/mes-aides-ui',
    environment => ['HOME=/home/main'],
    require     => [ File['/home/main/setup-pm2.sh'], Exec['chown pm2 home'] ],
    user        => 'main',
}

vcsrepo { '/home/main/mes-aides-ui':
    ensure   => latest,
    provider => git,
    require  => [ User['main'] ],
    revision => String(file('/opt/mes-aides/ui_target_revision'), "%t"),
    source   => 'https://github.com/betagouv/mes-aides-ui.git',
    user     => 'main',
    notify   => [ File['/home/main/mes-aides-ui/backend/config/production.js'] ],
}

file { '/home/main/mes-aides-ui/backend/config/production.js':
    ensure  => present, # creates a normal file if the file is missing
    replace => false,   # setting this to false allows file resources to initialize files without overwriting future changes
    owner   => 'main',
    group   => 'main',
    mode    => '644',
    source  => '/home/main/mes-aides-ui/backend/config/continuous_integration.js',
}


# Currently required - Failure during npm ci
# mes-aides-ui > betagouv-mes-aides-api > ludwig-api > connect-mongo > mongodb > kerberos
package { 'libkrb5-dev': }

# Install libfontconfig to generate PDFs with PhantomJS
package { 'libfontconfig': }

# Install Chromium to have Puppeteer dependencies installed as well
package { 'chromium-browser':
    ensure => 'present',
}

# https://github.com/GoogleChrome/puppeteer/blob/master/docs/troubleshooting.md#alternative-setup-setuid-sandbox
exec { 'setup setuid sandbox':
    command => 'chown root:root node_modules/puppeteer/.local-chromium/linux-*/chrome-linux/chrome_sandbox && chmod 4755 node_modules/puppeteer/.local-chromium/linux-*/chrome-linux/chrome_sandbox && cp -p node_modules/puppeteer/.local-chromium/linux-*/chrome-linux/chrome_sandbox /usr/local/sbin/chrome-devel-sandbox',
    path    => [ '/usr/local/bin', '/usr/bin', '/bin' ],
    cwd     => '/home/main/mes-aides-ui',
    user    => 'root',
    creates => '/usr/local/sbin/chrome-devel-sandbox',
    onlyif  => 'test -d node_modules/puppeteer'
}

::mesaides::nginx_config { 'mes-aides.gouv.fr':
    add_www_subdomain => true,
    is_default        => true,
    nginx_root        => '/home/main/mes-aides-ui',
    require           => [ Exec['startOrReload ma-web'] ],
    use_ssl           => find_file('/opt/mes-aides/use_ssl'),
    upstream_name     => 'mes_aides',
}

::mesaides::nginx_config { "${instance_name}.mes-aides.gouv.fr":
    require        => [ Exec['startOrReload ma-web'] ],
    nginx_root     => '/home/main/mes-aides-ui',
    use_ssl        => find_file("/opt/mes-aides/${instance_name}_use_ssl"),
    upstream_name  => 'mes_aides',
}

::mesaides::nginx_config { 'openfisca.mes-aides.gouv.fr':
    use_ssl          => find_file("/opt/mes-aides/${instance_name}_use_ssl"),
    upstream_name    => 'openfisca',
}

$venv_dir = '/home/main/venv_python3.6'


if find_file("/opt/mes-aides/${instance_name}_use_ssl") or find_file('/opt/mes-aides/use_ssl') {
    class { ::letsencrypt:
        config => {
            email => 'contact@mes-aides.gouv.fr',
        }
    }
}
