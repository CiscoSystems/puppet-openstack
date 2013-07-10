class openstack::ceph::common (
  $fsid,
  $auth_type = 'cephx'
) {

  class { 'ceph::conf':
    fsid            => $::ceph_monitor_fsid,
    auth_type       => $::ceph_auth_type,
    cluster_network => $::ceph_cluster_network,
    public_network  => $::ceph_public_network,
  }

  include ceph::apt::ceph

}
