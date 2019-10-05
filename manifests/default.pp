$instance_name = 'metal'

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

# Currently required - Failure during npm ci
# mes-aides-ui > betagouv-mes-aides-api > ludwig-api > connect-mongo > mongodb > kerberos
package { 'libkrb5-dev': }
