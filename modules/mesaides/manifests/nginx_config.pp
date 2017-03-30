define mesaides::nginx_config (
    $use_ssl = false,
    $webroot_path = '/var/www',
) {
    file { "/etc/nginx/sites-enabled/${name}.conf":
        content => template('mesaides/nginx_config.erb'),
        ensure  => file,
        group   => 'www-data',
        mode    => '600',
        owner   => 'www-data',
    }

    if $use_ssl {
        class { ::letsencrypt:
            config => {
                email => 'thomas.guillet@beta.gouv.fr',
                #server => 'https://acme-staging.api.letsencrypt.org/directory',
            }
        }

        file { $webroot_path:
            ensure => directory,
        }

        letsencrypt::certonly { $name:
            domains       => [ $name ],
            plugin        => 'webroot',
            require       => File[$webroot_path],
            webroot_paths => [$webroot_path],
        }
    }
}
