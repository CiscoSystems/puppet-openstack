#
# == Class: openstack::all
#
# Class that performs a basic openstack all in one installation.
#
# === Parameterrs
#
#  TODO public address should be optional.
#  [external_address] Public address used by vnchost. Required.
#  [external_interface] The interface used to route public traffic by the
#    network service.
#  [private_interface] The private interface used to bridge the VMs into a common network.
#  [floating_range] The floating ip range to be created. If it is false, then no floating ip range is created.
#    Optional. Defaults to false.
#  [fixed_range] The fixed private ip range to be created for the private VM network. Optional. Defaults to '10.0.0.0/24'.
#  [network_manager] The network manager to use for the nova network service.
#    Optional. Defaults to 'nova.network.manager.FlatDHCPManager'.
#  [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
#  [network_config] Used to specify network manager specific parameters .Optional. Defualts to {}.
#  [mysql_root_password] The root password to set for the mysql database. Optional. Defaults to sql_pass'.
#  [rabbit_password] The password to use for the rabbitmq user. Optional. Defaults to rabbit_pw'
#  [rabbit_user] The rabbitmq user to use for auth. Optional. Defaults to nova'.
#  [admin_email] The admin's email address. Optional. Defaults to someuser@some_fake_email_address.foo'.
#  [admin_password] The default password of the keystone admin. Optional. Defaults to ChangeMe'.
#  [keystone_db_password] The default password for the keystone db user. Optional. Defaults to keystone_pass'.
#  [keystone_admin_token] The default auth token for keystone. Optional. Defaults to keystone_admin_token'.
#  [nova_db_password] The nova db password. Optional. Defaults to nova_pass'.
#  [nova_user_password] The password of the keystone user for the nova service. Optional. Defaults to nova_pass'.
#  [glance_db_password] The password for the db user for glance. Optional. Defaults to 'glance_pass'.
#  [glance_user_password] The password of the glance service user. Optional. Defaults to 'glance_pass'.
#  [secret_key] The secret key for horizon. Optional. Defaults to 'dummy_secret_key'.
#  [verbose] If the services should log verbosely. Optional. Defaults to false.
#  [purge_nova_config] Whether unmanaged nova.conf entries should be purged. Optional. Defaults to true.
#  [libvirt_type] The virualization type being controlled by libvirt.  Optional. Defaults to 'kvm'.
#  [nova_volume] The name of the volume group to use for nova volume allocation. Optional. Defaults to 'nova-volumes'.
#
# === Examples
#
#  class { 'openstack::all':
#    external_address       => '192.168.0.3',
#    external_interface     => eth0,
#    private_interface    => eth1,
#    admin_email          => my_email@mw.com,
#    admin_password       => 'my_admin_password',
#    libvirt_type         => 'kvm',
#  }
#
# === Authors
#
# Dan Bode <bodepd@gmail.com>
#
#
class openstack::all(
  # passing in the external ipaddress is required
  $external_interface,
  $management_address,
  $management_interface,
  $floating_range          = false,
  $fixed_range             = '10.0.0.0/24',
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $network_config          = {},
  # middleware credentials
  $mysql_root_password     = undef,
  $rabbit_password         = 'rabbit_pw',
  $rabbit_user             = 'nova',
  # opestack credentials
  $admin_email             = 'someuser@some_fake_email_address.foo',
  $admin_password          = 'ChangeMe',
  $keystone_db_password    = 'keystone_pass',
  $keystone_admin_token    = 'keystone_admin_token',
  $keystone_admin_tenant   = 'openstack',
  $nova_db_password        = 'nova_pass',
  $nova_user_password      = 'nova_pass',
  $glance_db_password      = 'glance_pass',
  $glance_user_password    = 'glance_pass',
  $secret_key              = 'dummy_secret_key',
  # config
  $verbose                 = false,
  $auto_assign_floating_ip = false,
  $purge_nova_config       = true,
  $libvirt_type            = 'kvm',
  $nova_volume             = 'nova-volumes',
  # quantum config
  $network_api_class       = 'nova.network.quantumv2.api.API',
  $quantum_url             = 'http://127.0.0.1:9696',
  $quantum_auth_strategy   = 'keystone',
  $quantum_admin_tenant_name    = 'services',
  $quantum_admin_username       = 'quantum',
  $quantum_admin_password       = 'quantum',
  $quantum_admin_auth_url       = 'http://127.0.0.1:35357/v2.0',
  $quantum_ip_overlap           = false,
  $libvirt_vif_driver      = 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver',
  $libvirt_use_virtio_for_bridges       = 'True',
#guantum general
  $quantum_enabled              = true,
  $quantum_package_ensure       = present,
  $quantum_log_verbose          = "True",
  $quantum_log_debug            = "True",
  $quantum_bind_host            = "0.0.0.0",
  $quantum_bind_port            = "9696",
  $quantum_sql_connection       = "mysql://quantum:quantum@localhost/quantum",
  $quantum_auth_host            = "localhost",
  $quantum_auth_port            = "35357",
  $quantum_rabbit_host          = "localhost",
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
  $ovs_sql_connection       = "mysql://quantum:quantum@localhost/quantum", # must match quantum DB information
#quantum db
  $quantum_db_password      = "quantum",
  $quantum_db_name        = 'quantum',
  $quantum_db_user          = 'quantum',
  $quantum_db_host          = '127.0.0.1',
  $quantum_db_allowed_hosts = ['localhost','192.168.150.%'],
  $quantum_db_charset       = 'latin1',
  $quantum_db_cluster_id    = 'localzone',
#quantum keystone user/password
  $quantum_email              = 'quantum@localhost',
  $quantum_public_address     = '127.0.0.1',
  $quantum_admin_address      = '127.0.0.1',
  $quantum_internal_address   = '127.0.0.1',
  $quantum_port               = '9696',
  $quantum_region             = 'RegionOne',
#quantum l3
  $l3_interface_driver         = "quantum.agent.linux.interface.OVSInterfaceDriver",
  $l3_use_namespaces           = "False",
  $l3_router_id                = "7e5c2aca-bbac-44dd-814d-f2ea9a4003e4",
  $l3_gateway_external_net_id  = "3f8699d7-f221-421a-acf5-e41e88cfd54f",
  $l3_metadata_ip              = "169.254.169.254",
  $l3_external_network_bridge  = "br-ex",
  $l3_root_helper              = "sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf",
#quantum dhcp
  $dhcp_state_path         = "/var/lib/quantum",
  $dhcp_interface_driver   = "quantum.agent.linux.interface.OVSInterfaceDriver",
  $dhcp_driver        = "quantum.agent.linux.dhcp.Dnsmasq",
  $dhcp_use_namespaces     = "False",
  $dhcp_root_helper        = "sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf",
) {


  #
  # indicates that all nova config entries that we did
  # not specifify in Puppet should be purged from file
  #
  if ($purge_nova_config) {
    resources { 'nova_config':
      purge => true,
    }
  }

  # set up mysql server
  if (!defined(Class[mysql::server])) {
    class { 'mysql::server':
      config_hash => {
        # the priv grant fails on precise if I set a root password
        'root_password' => $mysql_root_password,
        'bind_address'  => '0.0.0.0'
      }
    }
  }

  ####### KEYSTONE ###########

  # set up keystone database
  class { 'keystone::db::mysql':
    password => $keystone_db_password,
  }
  # set up the keystone config for mysql
  class { 'keystone::config::mysql':
    password => $keystone_db_password,
  }
  # set up keystone
  class { 'keystone':
    admin_token  => $keystone_admin_token,
    bind_host    => '0.0.0.0',
    log_verbose  => $verbose,
    log_debug    => $verbose,
    catalog_type => 'sql',
  }
  # set up keystone admin users
  class { 'keystone::roles::admin':
    email        => $admin_email,
    password     => $admin_password,
    admin_tenant => $keystone_admin_tenant,
  }
  # set up the keystone service and endpoint
  class { 'keystone::endpoint': }

  ######## END KEYSTONE ##########

  ######## BEGIN GLANCE ##########

  # set up keystone user, endpoint, service
  class { 'glance::keystone::auth':
    password => $glance_user_password,
    public_address => $management_address,
  }

  # creat glance db/user/grants
  class { 'glance::db::mysql':
    host     => '127.0.0.1',
    password => $glance_db_password,
  }

  # configure glance api
  class { 'glance::api':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
  }

  # configure glance to store images to disk
  class { 'glance::backend::file': }

  class { 'glance::registry':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
  }


  ######## END GLANCE ###########

  ######## BEGIN NOVA ###########

  class { 'nova::keystone::auth':
    password => $nova_user_password,
    public_address => $management_address,
  }

  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
  }

  class { 'nova::db::mysql':
    password => $nova_db_password,
    host     => $management_address,
  }

  class { 'nova':
    sql_connection     => "mysql://nova:${nova_db_password}@${management_address}/nova",
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => "${management_address}:9292",
    verbose            => $verbose,
  }

  class { 'nova::api':
    enabled        => true,
    admin_password => $nova_user_password,
  }

  # a bunch of nova services that require no configuration
  class { [
    'nova::scheduler',
    'nova::objectstore',
    'nova::volume',
    'nova::cert',
    'nova::consoleauth'
  ]:
    enabled => true
  }

  class { 'nova::vncproxy':
    enabled => true,
    host    => $public_hostname,
  }

  class { 'nova::compute':
    enabled                       => true,
    vnc_enabled                   => $vnc_enabled,
    vncserver_proxyclient_address => $management_address,
    vncproxy_host                 => $management_address,
  }

  class { 'nova::compute::libvirt':
    libvirt_type     => $libvirt_type,
    vncserver_listen => $management_address,
  }

  class { 'nova::volume::iscsi':
    volume_group     => $nova_volume,
    iscsi_ip_address => $management_address,
  }

  # set up networking
if $network_manager =~ /quantum/ {
  $enable_network_service = false
} 
### Nova Network Floating IPs ##
  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip':   value => 'True'; }
  }

# set up configuration for networking
  class { 'nova::network':
    private_interface => $management_interface,
    public_interface  => $external_interface,
    fixed_range       => $fixed_range,
    floating_range    => false,
    network_manager   => $network_manager,
    config_overrides  => $network_config,
    create_networks   => false,
    enabled           => $enable_network_service,
    install_service   => $enable_network_service,
    network_api_class   => $network_api_class,
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

### Start Quantum Section ###
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

class { "quantum::server":
  package_ensure       => $quantum_package_ensure,
  auth_host            => $quantum_auth_host,
  auth_password        => $quantum_admin_password,
}

# The CLI client
class { "quantum::client": }

# The plugin for the server
class { "quantum::plugins::ovs":
    package_ensure       => $quantum_package_ensure,
    tenant_network_type  => $ovs_tenant_network_type,
    network_vlan_ranges  => $ovs_network_vlan_ranges,
    tunnel_id_ranges     => $ovs_tunnel_id_ranges,
    sql_connection       => $ovs_sql_connection,
}
# The OVS database
class { "quantum::db::mysql":
  password      => $quantum_db_password,
  dbname        => $quantum_db_name,
  user          => $quantum_db_user,
  host          => $quantum_db_host,
  allowed_hosts => $quantum_db_allowed_hosts,
  charset       => $quantum_db_charset,
  cluster_id    => $quantum_db_cluster_id,
} -> Class["quantum::plugins::ovs"]


# Tell keystone quantum should be permitted to connect as a service
class { "quantum::keystone::auth":
  password           => $quantum_admin_password,
  auth_name          => $quantum_admin_username,
  email              => $quantum_email,
  tenant             => $quantum_admin_tenant_name,
  configure_endpoint => true,
  service_type       => 'network',
  public_address     => $quantum_public_address,
  admin_address      => $quantum_admin_address,
  internal_address   => $quantum_internal_address,
  port               => $quantum_port,
  region             => $quantum_region,
}
class {"quantum::agents::l3":
  package_ensure       => $quantum_package_ensure,
  interface_driver         => $l3_interface_driver,
  use_namespaces           => $l3_use_namespaces,
  router_id                => $router_id,
  gateway_external_net_id  => $gateway_external_net_id,
  metadata_ip              => $l3_metadata_ip,
  external_network_bridge  => $external_network_bridge,
  root_helper              => $l3_root_helper,
  auth_password            => $quantum_admin_password,
  auth_tenant              => $quantum_admin_tenant_name,
}

class { "quantum::agents::ovs":
  package_ensure           => $quantum_package_ensure,
  bridge_uplinks           => $ovs_bridge_uplinks,
  bridge_mappings          => $ovs_bridge_mappings,
  enable_tunneling         => $ovs_enable_tunneling,
  local_ip                 => $ovs_local_ip,
  integration_bridge       => $ovs_integration_bridge,
  tunnel_bridge            => $ovs_tunnel_bridge,
  root_helper              => $ovs_root_helper,
}

class {"quantum::agents::dhcp":
  package_ensure       => $quantum_package_ensure,
  state_path         => $dhcp_state_path,
  interface_driver   => $dhcp_interface_driver,
  dhcp_driver        => $dhcp_driver,
  use_namespaces     => $dhcp_use_namespaces,
  root_helper        => $dhcp_root_helper,
}


  ######## Horizon ########

  class { 'memcached':
    listen_ip => $management_address,
  }

  class { 'horizon':
    secret_key => $secret_key,
  }

  ######## End Horizon #####

}
