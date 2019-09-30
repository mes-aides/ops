
$instance_name = 'metal'

file { '/opt/mes-aides/update.sh':
    ensure => file,
    group  => 'root',
    mode   => '700',
    owner  => 'root',
    source => 'puppet:///modules/mesaides/update.sh',
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
