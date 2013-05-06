#
# This class is intended to serve as
# a way of deploying compute nodes.
#
# This currently makes the following assumptions:
#   - libvirt is used to manage the hypervisors
#   - flatdhcp networking is used
#   - glance is used as the backend for the image service
#
# TODO - I need to make the choise of networking configurable
#
#
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [public_interface] Public interface used to route public traffic. Optional.
#   Defaults to false.
# [fixed_range] Range of ipv4 network for vms.
# [network_manager] Nova network manager to use.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [sql_connection] SQL connection information. Optional. Defaults to false
#   which indicates that exported resources will be used to determine connection
#   information.
# [nova_user_password] Nova service password.
#  [rabbit_host] RabbitMQ host. False indicates it should be collected.
#    Optional. Defaults to false,
#  [rabbit_password] RabbitMQ password. Optional. Defaults to  'rabbit_pw',
#  [rabbit_user] RabbitMQ user. Optional. Defaults to 'nova',
#  [glance_api_servers] List of glance api servers of the form HOST:PORT
#    delimited by ':'. False indicates that the resource should be collected.
#    Optional. Defaults to false,
#  [libvirt_type] Underlying libvirt supported hypervisor.
#    Optional. Defaults to 'kvm',
#  [vncproxy_host] Host that serves as vnc proxy. Optional.
#    Defaults to false. False indicates that a vnc proxy should not be configured.
#  [vnc_enabled] Rather vnc console should be enabled.
#    Optional. Defaults to 'true',
#  [verbose] Rather components should log verbosely.
#    Optional. Defaults to false.
#  [manage_volumes] Rather nova-volume should be enabled on this compute node.
#    Optional. Defaults to false.
#  [nova_volumes] Name of volume group in which nova-volume will create logical volumes.
#    Optional. Defaults to nova-volumes.
#
class openstack::compute(
  $private_interface,
  $internal_address,
  # networking config
  $public_interface    = undef,
  $fixed_range         = '10.0.0.0/16',
  $network_manager     = 'nova.network.manager.FlatDHCPManager',
  $multi_host          = false,
  $network_config      = {},
  # my address
  # conection information
  $sql_connection      = false,
  $nova_user_password  = 'nova_pass',
  $rabbit_host         = false,
  $rabbit_password     = 'rabbit_pw',
  $rabbit_user         = 'nova',
  $glance_api_servers  = false,
  # nova compute configuration parameters
  $libvirt_type        = 'kvm',
  $vncproxy_host       = false,
  $vnc_enabled         = 'true',
  $verbose             = false,
  ## deprecated
  # $manage_volumes      = false,
  # $nova_volume         = 'nova-volumes',
  ##
  $prevent_db_sync     = true,
  # quantum config
  $network_api_class       = 'nova.network.quantumv2.api.API',
  $quantum_url             = 'http://172.29.74.194:9696',
  $quantum_auth_strategy   = 'keystone',
  $quantum_admin_tenant_name    = 'services',
  $quantum_admin_username       = 'quantum',
  $quantum_admin_password       = 'quantum',
  $quantum_admin_auth_url       = 'http://172.29.74.194:35357/v2.0',
  $quantum_ip_overlap           = false,
  $libvirt_vif_driver      = 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver',
  $libvirt_use_virtio_for_bridges       = 'True',
  $host         = 'compute',
#quantum general
  $quantum_enabled              = true,
  $quantum_package_ensure       = present,
  $quantum_log_verbose          = "True",
  $quantum_log_debug            = "True",
  $quantum_bind_host            = "0.0.0.0",
  $quantum_bind_port            = "9696",
  $quantum_sql_connection       = "mysql://quantum:quantum@172.29.74.194/quantum",
  $quantum_auth_host            = "172.29.74.194",
  $quantum_auth_port            = "35357",
  $quantum_rabbit_host          = "172.29.74.194",
  $quantum_rabbit_port          = "5672",
  $quantum_rabbit_user          = "quantum",
  $quantum_rabbit_password      = "quantum",
  $quantum_rabbit_virtual_host  = "/quantum",
  $quantum_control_exchange     = "quantum",
  $quantum_core_plugin            = "quantum.plugins.openvswitch.ovs_quantum_plugin.OVSQuantumPluginV2",
  $quantum_mac_generation_retries = 16,
  $quantum_dhcp_lease_duration    = 120,
#quantum ovs
  $ovs_bridge_uplinks      = ['br-ex:eth0.40'],
  $ovs_bridge_mappings      = ['default:br-ex'],
  $ovs_tenant_network_type  = "vlan",
  $ovs_network_vlan_ranges  = "default:1000:2000",
  $ovs_integration_bridge   = "br-int",
  $ovs_enable_tunneling    = "False",
  $ovs_tunnel_bridge        = "br-tun",
  $ovs_tunnel_id_ranges     = "1:1000",
  $ovs_local_ip             = "10.0.0.1",
  $ovs_server               = false,
  $ovs_root_helper          = "sudo quantum-rootwrap /etc/quantum/rootwrap.conf",
  $ovs_sql_connection       = "mysql://quantum:quantum@172.29.74.194/quantum",
# cinder db
  $cinder_compute_enabled   = true,
  $cinder_db_name              = 'cinder',
  $cinder_db_password          = 'cinder',
  $cinder_db_user              = 'cinder',
  $cinder_user_password        = 'cinder_pass',

) {

  class { 'nova':
    sql_connection     => $sql_connection,
    rabbit_host        => $rabbit_host,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_api_servers,
    prevent_db_sync    => $prevent_db_sync,
    verbose            => $verbose,
  }

  class { 'nova::compute':
    enabled                        => true,
    vnc_enabled                    => $vnc_enabled,
    vncserver_proxyclient_address  => $internal_address,
    vncproxy_host                  => $vncproxy_host,
  }

  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $internal_address,
  }

  # if the compute node should be configured as a multi-host
  # compute installation
  if $multi_host {

    include keystone::python

    nova_config {
      'multi_host':        value => 'True';
      'send_arp_for_ha':   value => 'True';
    }
    if ! $public_interface {
      fail('public_interface must be defined for multi host compute nodes')
    }
    $enable_network_service = true
    class { 'nova::api':
      enabled           => true,
      admin_tenant_name => 'services',
      admin_user        => 'nova',
      admin_password    => $nova_user_password,
    }
  } else {
    $enable_network_service = false
    nova_config {
      'multi_host':        value => 'False';
      'send_arp_for_ha':   value => 'False';
    }
  }

  # set up configuration for networking
  class { 'nova::network':
    private_interface => $private_interface,
    public_interface  => $public_interface,
    fixed_range       => $fixed_range,
    floating_range    => false,
    network_manager   => $network_manager,
    config_overrides  => $network_config,
    create_networks   => false,
    enabled           => $enable_network_service,
    install_service   => $enable_network_service,
    network_api_class	=> $network_api_class,
    quantum_url => $quantum_url,
    quantum_auth_strategy => $quantum_auth_strategy,
    quantum_admin_tenant_name => $quantum_admin_tenant_name,
    quantum_admin_username => $quantum_admin_username,
    quantum_admin_password => $quantum_admin_password,
    quantum_admin_auth_url => $quantum_admin_auth_url,
    quantum_ip_overlap     => $quantum_ip_overlap,
    libvirt_vif_driver => $libvirt_vif_driver,
    libvirt_use_virtio_for_bridges => $libvirt_use_virtio_for_bridges, 
  }

  class { "quantum":
    enabled              => $quantum_enabled, 
    package_ensure       => $quantum_package_ensure, 
    verbose              => $quantum_log_verbose,
    debug                => $quantum_log_debug,
    bind_host            => $quantum_bind_host,
    bind_port            => $quantum_bind_port,
    rabbit_host          => $quantum_rabbit_host,
    rabbit_port          => $quantum_rabbit_port,
    rabbit_user          => $quantum_rabbit_user,
    rabbit_password      => $quantum_rabbit_password,
    rabbit_virtual_host  => $quantum_rabbit_virtual_host,
    control_exchange     => $quantum_control_exchange,
    core_plugin            => $quantum_core_plugin,
    mac_generation_retries => $quantum_mac_generation_retries,
    dhcp_lease_duration    => $quantum_dhcp_lease_duration,
  }

  class { "quantum::agents::ovs":
    package_ensure       => $quantum_package_ensure,
    bridge_uplinks           => $ovs_bridge_uplinks,
    bridge_mappings          => $ovs_bridge_mappings,
    enable_tunneling         => $ovs_enable_tunneling,
    local_ip                 => $ovs_local_ip,
    integration_bridge       => $ovs_integration_bridge,
    tunnel_bridge            => $ovs_tunnel_bridge,
    root_helper              => $ovs_root_helper,
  }

  ######## BEGIN CINDER ########
  if $cinder_compute_enabled {
    class { 'cinder::base':
      rabbit_userid    => $rabbit_user,
      rabbit_password  => $rabbit_password,
      sql_connection   => "mysql://${cinder_db_user}:${cinder_db_password}@127.0.0.1/${cinder_db_name}",
    }
    if $cinder_storage_driver == 'netapp' {
      class { 'cinder::volume::netapp':
        $netapp_wsdl_url       = '',
        $netapp_login          = '',
        $netapp_password       = '',
      }
    }
    elsif $cinder_storage_driver == 'nfs' {
      class { 'cinder::volume::nfs':
        $nfs_shares_config = '',
      }
    }
    else {
      class { 'cinder::volume::iscsi':
        iscsi_ip_address => $internal_address,
      }
      class { 'cinder::setup_test_volume': }
    }
  }
  ######## END CINDER ########

}
