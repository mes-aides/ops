define mesaides::automation_script (
    $accepted_head_types = [],
    $manifest_name = undef,
    $post_command = undef,
) {
    file { $name:
        ensure => file,
        group  => 'root',
        mode   => '700',
        owner  => 'root',
        content => template('mesaides/automation_script.erb'),
    }
}
