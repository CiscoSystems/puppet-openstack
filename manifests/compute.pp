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
  $virtual_address     = $virtual_address,
  # networking config
  $public_interface    = undef,
  $fixed_range         = '10.0.0.0/16',
  $network_manager     = 'nova.network.manager.FlatDHCPManager',
  $multi_host          = false,
  $network_config      = {},
  $api_bind_address    = '0.0.0.0',
  # my address
  # conection information
  #$sql_connection      = false,
  $nova_user_password  = 'nova_pass',
  #$rabbit_host         = '192.168.220.41',
  $rabbit_addresses,
  $rabbit_password     = 'rabbit_pw',
  $rabbit_user         = 'nova',
  $glance_api_servers  = false,
  # nova compute configuration parameters
  $libvirt_type        = 'kvm',
  $vncproxy_host       = false,
  $vnc_enabled         = 'true',
  $verbose             = false,
  $manage_volumes      = false,
  $nova_db_password    = 'nova_pass',
  $nova_volume         = 'nova-volumes',
  #$prevent_db_sync     = true
) {

  #$glance_api_servers = "${virtual_address}:9292"
  $nova_db = "mysql://nova:${nova_db_password}@${virtual_address}/nova"

  if ($export_resources) {
    # export all of the things that will be needed by the clients
    #@@nova_config { 'rabbit_host': value => $internal_address }
    #Nova_config <| title == 'rabbit_addresses' |>
    @@nova_config { 'sql_connection': value => $sql_connection }
    Nova_config <| title == 'sql_connection' |>
    #@@nova_config { 'glance_api_servers': value => $glance_api_servers }
    #Nova_config <| title == 'glance_api_servers' |>
    #@@nova_config { 'novncproxy_base_url': value => "http://${virtual_address}:6080/vnc_auto.html" }
    $sql_connection    = false
    #$glance_connection = false
    #$rabbit_connection = false
  } else {
    $sql_connection    = $nova_db
    #$glance_connection = $glance_api_servers
    #$rabbit_connection = $internal_address
  }

  class { 'nova':
    sql_connection     => $sql_connection,
    rabbit_host        => $rabbit_host,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_api_servers,
    #prevent_db_sync    => $prevent_db_sync,
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
      auth_host         => $virtual_address,
      api_bind_address  => $api_bind_address,
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
  }

  if $manage_volumes {

    class { 'nova::volume':
      enabled => true, 
    }

    class { 'nova::volume::iscsi':
      volume_group     => $nova_volume,
      iscsi_ip_address => $internal_address,
    } 
  }

}
