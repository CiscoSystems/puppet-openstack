define openstack::apt::pin($pin_spec,
                           $pin_priority = 990) {
    if (!defined(File["/etc/apt/preferences.d"])) {
        file { "/etc/apt/preferences.d":
            ensure => directory
        }
    }
    file { "/etc/apt/preferences.d/${name}.conf":
        content => template('openstack/apt-pinning.conf.erb'),
        ensure => "present",
    } 
}
