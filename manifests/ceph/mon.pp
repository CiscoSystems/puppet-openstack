class openstack::ceph::mon (
  $id
) {

  class { 'openstack::ceph::common':
    fsid      => $::ceph_monitor_fsid,
    auth_type => $::ceph_auth_type,
  }

  ceph::mon { $id:
    monitor_secret => $::ceph_monitor_secret,
    mon_port       => 6789,
    mon_addr       => $::ceph_monitor_address,
  }

}
