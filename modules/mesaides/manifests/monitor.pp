define mesaides::monitor () {
    file { '/opt/mes-aides/monitor.sh':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '755',
        source => 'puppet:///modules/mesaides/monitor.sh',
    }

    file { '/opt/mes-aides/monitor-server.js':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '755',
        source => 'puppet:///modules/mesaides/monitor-server.js',
    }

    file { '/etc/init/ma-monitor.conf':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '644',
        source => 'puppet:///modules/mesaides/ma-monitor.conf',
    }

    service { 'ma-monitor':
        ensure  => 'running',
        require => File['/etc/init/ma-monitor.conf'],
    }

    ::mesaides::nginx_config { $name:
        require          => Service['ma-monitor'],
        upstream_name    => 'monitor',
    }
}
