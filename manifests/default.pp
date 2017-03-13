class { 'nginx': }

include '::mongodb::server'

class { 'nodejs':
    repo_url_suffix => '0.10',
    # Version name is mandatory because there seems to be a priority issue
    # which leads to 4.x version being installed
    nodejs_package_ensure => '0.10.48-1nodesource1~trusty1',
}

package { 'bower':
    provider => 'npm',
}

include git
