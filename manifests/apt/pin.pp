define openstack::apt::pin($pin_spec,
                           $pin_priority = 990) {
    file { "/etc/apt/preferences.d/${name}.conf":
        content => template('openstack/apt-pinning.conf.erb'),
        ensure => "present",
    } 
}
