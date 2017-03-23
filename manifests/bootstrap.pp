# Install gem in Puppet ruby environment to avoid full ruby install on host
# https://docs.puppet.com/puppet/4.9/type.html#package-provider-puppet_gem
package { 'librarian-puppet':
    provider => 'puppet_gem',
}

file { [ '/opt',
    '/opt/mes-aides-bootstrap',
     ]:
    ensure => directory,
}

file { '/opt/mes-aides-bootstrap/Puppetfile':
    ensure => file,
    source => [
        'puppet:///modules/mesaides/Puppetfile.bootstrap',
        'https://raw.githubusercontent.com/sgmap/mes-aides-ops/master/modules/mesaides/files/Puppetfile.bootstrap',
    ],
}

# Use gem install in ruby embedded in Puppet
# https://docs.puppet.com/puppet/4.9/whered_it_go.html#private-bin-directories
exec { 'install puppet modules':
    command     => '/opt/puppetlabs/puppet/bin/librarian-puppet install',
    cwd         => '/opt/mes-aides-bootstrap',
    environment => ['HOME=/root'],
}
