class { 'nginx': }

include '::mongodb::server'

class { 'nodejs':
    # Version name is mandatory because there seems to be a priority issue
    # which leads to 4.x version being installed
    nodejs_package_ensure => '0.10.48-1nodesource1~trusty1',
    repo_url_suffix => '0.10',
}

package { 'bower':
    provider => 'npm',
}

include git

vcsrepo { '/home/ubuntu/mes-aides-ui':
    ensure   => present,
    provider => git,
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
    # https://docs.puppet.com/puppet/latest/types/exec.html#exec-attribute-timeout
    #  default is 300 (seconds)
    timeout     => 600,
    user        => 'ubuntu',
}

exec { 'test mes-aides-ui':
    command     => '/usr/bin/npm test',
    cwd         => '/home/ubuntu/mes-aides-ui',
    environment => ['HOME=/home/ubuntu'],
    user        => 'ubuntu',
}
