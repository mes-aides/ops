package { 'git': }

vcsrepo { '/opt/mes-aides/ops':
    ensure   => latest,
    provider => git,
    revision => String(file('/opt/mes-aides/ops_target_revision'), "%t"),
    source   => 'https://git@github.com/betagouv/mes-aides-ops.git',
}

# Use gem install in ruby embedded in Puppet
# https://docs.puppet.com/puppet/4.9/whered_it_go.html#private-bin-directories
exec { 'install puppet modules':
    command     => '/opt/puppetlabs/puppet/bin/librarian-puppet install',
    cwd         => '/opt/mes-aides/ops',
    environment => ['HOME=/root'],
}
