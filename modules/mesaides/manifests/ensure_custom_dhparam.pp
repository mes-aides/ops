# https://weakdh.org/
class mesaides::ensure_custom_dhparam {
    exec {'ensure custom dhparam':
        command => '/usr/bin/openssl dhparam -out /etc/ssl/private/dhparam.pem 2048',
        # default is 300 (seconds)
        timeout => 600, # 10 minutes
        unless  => '/usr/bin/test -e /etc/ssl/private/dhparam.pem',
    }
}
