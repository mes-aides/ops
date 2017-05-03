define mesaides::nginx_config (
    $use_ssl = false,
    $webroot_path = '/var/www',
) {
    include ::nginx

    file { "/etc/nginx/sites-enabled/${name}.conf":
        content => template('mesaides/nginx_config.erb'),
        ensure  => file,
        group   => 'www-data',
        mode    => '600',
        notify  => Class['nginx::service'],
        owner   => 'www-data',
    }

    if $use_ssl {
        include mesaides::generate_custom_dhparam

        class { ::letsencrypt:
            config => {
                email => 'contact@mes-aides.gouv.fr',
            }
        }

        file { $webroot_path:
            ensure => directory,
        }

        letsencrypt::certonly { $name:
            domains       => [ $name ],
            notify        => Service['nginx'],
            plugin        => 'webroot',
            require       => [ File[$webroot_path], File["/etc/nginx/sites-enabled/${name}.conf"] ],
            webroot_paths => [ $webroot_path ],
        }
    }
}
