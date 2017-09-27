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

    file { '/etc/systemd/system/ma-monitor.service':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '644',
        source => 'puppet:///modules/mesaides/ma-monitor.service',
    }

    service { 'ma-monitor':
        ensure  => 'running',
        require => File['/etc/systemd/system/ma-monitor.conf'],
    }

    ::mesaides::nginx_config { $name:
        proxied_endpoint => 'http://localhost:8887',
        require          => Service['ma-monitor'],
    }
}
