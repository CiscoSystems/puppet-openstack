define openstack::apt::pin($pin_spec,
                           $pin_priority = 990) {
    file { "/etc/apt/preferences.d/${name}.pref":
        content => template('openstack/apt-pinning.pref.erb'),
        ensure => "present",
    } 
}
