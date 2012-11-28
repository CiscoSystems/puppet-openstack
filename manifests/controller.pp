#
# This can be used to build out the simplest openstack controller
#
#
# $export_resources - Whether resources should be exported
#
# [public_interface] Public interface used to route public traffic. Required.
# [public_address] Public address for public endpoints. Required.
# [private_interface] Interface used for vm networking connectivity. Required.
# [internal_address] Internal address used for management. Required.
# [mysql_root_password] Root password for mysql server.
# [admin_email] Admin email.
# [admin_password] Admin password.
# [keystone_db_password] Keystone database password.
# [keystone_admin_token] Admin token for keystone.
# [glance_db_password] Glance DB password.
# [glance_user_password] Glance service user password.
# [nova_db_password] Nova DB password.
# [nova_user_password] Nova service password.
# [rabbit_password] Rabbit password.
# [rabbit_user] Rabbit User.
# [network_manager] Nova network manager to use.
# [fixed_range] Range of ipv4 network for vms.
# [floating_range] Floating ip range to create.
# [create_networks] Rather network and floating ips should be created.
# [num_networks] Number of networks that fixed range should be split into.
# [multi_host] Rather node should support multi-host networking mode for HA.
#   Optional. Defaults to false.
# [auto_assign_floating_ip] Rather configured to automatically allocate and
#   assign a floating IP address to virtual instances when they are launched.
#   Defaults to false.
# [network_config] Hash that can be used to pass implementation specifc
#   network settings. Optioal. Defaults to {}
# [verbose] Rahter to log services at verbose.
# [export_resources] Rather to export resources.
# Horizon related config - assumes puppetlabs-horizon code
# [secret_key]          secret key to encode cookies, …
# [cache_server_ip]     local memcached instance ip
# [cache_server_port]   local memcached instance port
# [swift]               (bool) is swift installed
# [glance_on_swift]     (bool) is glance to run on swift or on file
# [quantum]             (bool) is quantum installed
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [horizon_app_links]     array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
# [horizon_top_links]     just like horizon_app_links, but shown in the header
#
# [enabled] Whether services should be enabled. This parameter can be used to
#   implement services in active-passive modes for HA. Optional. Defaults to true.
class openstack::controller(
  # my address
  $public_address,
  $public_interface,
  $private_interface,
  $internal_address,
  $admin_address           = $internal_address,
  # connection information
  $mysql_root_password     = undef,
  $admin_email             = 'some_user@some_fake_email_address.foo',
  $admin_password          = 'ChangeMe',
  $keystone_db_password    = 'keystone_pass',
  $keystone_admin_token    = 'keystone_admin_token',
  $keystone_admin_tenant   = 'openstack',
  $glance_db_password      = 'glance_pass',
  $glance_user_password    = 'glance_pass',
  $nova_db_password        = 'nova_pass',
  $nova_user_password      = 'nova_pass',
  $rabbit_password         = 'rabbit_pw',
  $rabbit_user             = 'nova',
  # network configuration
  # this assumes that it is a flat network manager
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  # this number has been reduced for performance during testing
  $fixed_range             = '10.0.0.0/16',
  $floating_range          = false,
  $create_networks         = true,
  $num_networks            = 1,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
  # TODO need to reconsider this design...
  # this is where the config options that are specific to the network
  # types go. I am not extremely happy with this....
  $network_config          = {},
  # I do not think that this needs a bridge?
  $verbose                 = false,
  $export_resources        = true,
  $secret_key              = 'dummy_secret_key',
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $swift                   = false,
  $glance_on_swift         = false,
  $quantum                 = false,
  $horizon_app_links       = false,
  $horizon_top_links       = false,
  $enabled                 = true,
  # quantum config
  $network_api_class       = 'nova.network.quantumv2.api.API',
  $quantum_url             = 'http://127.0.0.1:9696',
  $quantum_auth_strategy   = 'keystone',
  $quantum_admin_tenant_name    = 'services',
  $quantum_admin_username       = 'quantum',
  $quantum_admin_password       = 'quantum',
  $quantum_admin_auth_url       = 'http://127.0.0.1:35357/v2.0',
  $libvirt_vif_driver      = 'nova.virt.libvirt.vif.LibvirtOpenVswitchDriver',
  $libvirt_use_virtio_for_bridges       = 'True',
  $host         = 'controller',
#guantum general
  $quantum_enabled              = true,
  $qunatum_package_ensure       = present,
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
  $ovs_sql_connection       = "mysql://quantum:quantum@localhost/quantum",
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

  $glance_api_servers = "${internal_address}:9292"
  $nova_db = "mysql://nova:${nova_db_password}@${internal_address}/nova"

  if ($export_resources) {
    # export all of the things that will be needed by the clients
    @@nova_config { 'rabbit_host': value => $internal_address }
    Nova_config <| title == 'rabbit_host' |>
    @@nova_config { 'sql_connection': value => $nova_db }
    Nova_config <| title == 'sql_connection' |>
    @@nova_config { 'glance_api_servers': value => $glance_api_servers }
    Nova_config <| title == 'glance_api_servers' |>
    @@nova_config { 'novncproxy_base_url': value => "http://${public_address}:6080/vnc_auto.html" }
    $sql_connection    = false
    $glance_connection = false
    $rabbit_connection = false
  } else {
    $sql_connection    = $nova_db
    $glance_connection = $glance_api_servers
    $rabbit_connection = $internal_address
  }

  ####### DATABASE SETUP ######

  # set up mysql server
  if (!defined(Class[mysql::server])) {
    class { 'mysql::server':
      config_hash => {
        # the priv grant fails on precise if I set a root password
        # TODO I should make sure that this works
        'root_password' => $mysql_root_password,
        'bind_address'  => '0.0.0.0'
      },
      enabled => $enabled,
    }
  }
  if ($enabled) {
    # set up all openstack databases, users, grants
    class { 'keystone::db::mysql':
      password => $keystone_db_password,
    }
    Class['glance::db::mysql'] -> Class['glance::registry']
    class { 'glance::db::mysql':
      host     => '127.0.0.1',
      password => $glance_db_password,
    }
    # TODO should I allow all hosts to connect?
    class { 'nova::db::mysql':
      password      => $nova_db_password,
      host          => $internal_address,
      allowed_hosts => '%',
    }
  }

  ####### KEYSTONE ###########

  # set up keystone
  class { 'keystone':
    admin_token  => $keystone_admin_token,
    # we are binding keystone on all interfaces
    # the end user may want to be more restrictive
    bind_host    => '0.0.0.0',
    log_verbose  => $verbose,
    log_debug    => $verbose,
    catalog_type => 'sql',
    enabled      => $enabled,
  }
  # set up keystone database
  # set up the keystone config for mysql
  class { 'keystone::config::mysql':
    password => $keystone_db_password,
  }

  if ($enabled) {
    # set up keystone admin users
    class { 'keystone::roles::admin':
      email        => $admin_email,
      password     => $admin_password,
      admin_tenant => $keystone_admin_tenant,
    }
    # set up the keystone service and endpoint
    class { 'keystone::endpoint':
      public_address   => $public_address,
      internal_address => $internal_address,
      admin_address    => $admin_address,
    }
    # set up glance service,user,endpoint
    class { 'glance::keystone::auth':
      password         => $glance_user_password,
      public_address   => $public_address,
      internal_address => $internal_address,
      admin_address    => $admin_address,
      before           => [Class['glance::api'], Class['glance::registry']]
    }
    # set up nova serice,user,endpoint
    class { 'nova::keystone::auth':
      password         => $nova_user_password,
      public_address   => $public_address,
      internal_address => $internal_address,
      admin_address    => $admin_address,
      before           => Class['nova::api'],
    }
  }

  ######## END KEYSTONE ##########

  ######## BEGIN GLANCE ##########


  class { 'glance::api':
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => '127.0.0.1',
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    enabled           => $enabled,
  }
  if $glance_on_swift {
    class { 'glance::backend::swift':
      swift_store_user => 'openstack:admin',
      swift_store_key => $admin_password,
      swift_store_auth_address => "http://$internal_address:5000/v2.0/",
      swift_store_container => 'glance',
      swift_store_create_container_on_put => 'true'
    }
  } else {
    class { 'glance::backend::file': }
  }
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
    enabled           => $enabled,
  }

  ######## END GLANCE ###########

  ######## BEGIN NOVA ###########


  class { 'nova::rabbitmq':
    userid   => $rabbit_user,
    password => $rabbit_password,
    enabled  => $enabled,
  }

  # TODO I may need to figure out if I need to set the connection information
  # or if I should collect it
  class { 'nova':
    sql_connection     => $sql_connection,
    # this is false b/c we are exporting
    rabbit_host        => $rabbit_connection,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_connection,
    verbose            => $verbose,
  }

  class { 'nova::api':
    enabled           => $enabled,
    # TODO this should be the nova service credentials
    #admin_tenant_name => 'openstack',
    #admin_user        => 'admin',
    #admin_password    => $admin_service_password,
    admin_tenant_name => 'services',
    admin_user        => 'nova',
    admin_password    => $nova_user_password,
  }

  class { [
    'nova::cert',
    'nova::consoleauth',
    'nova::scheduler',
    'nova::objectstore',
    'nova::vncproxy'
  ]:
    enabled => $enabled,
  }

  if $multi_host {
    nova_config { 'multi_host':   value => 'True'; }
    $enable_network_service = false
  } else {
    if $enabled == true {
      $enable_network_service = true
    } else {
      $enable_network_service = false
    }
  }

  if $enabled {
    $really_create_networks = $create_networks
  } else {
    $really_create_networks = false
  }

  # set up networking
  class { 'nova::network':
    private_interface => $private_interface,
    public_interface  => $public_interface,
    fixed_range       => $fixed_range,
    floating_range    => $floating_range,
    network_manager   => $network_manager,
    config_overrides  => $network_config,
    create_networks   => $really_create_networks,
    num_networks      => $num_networks,
    enabled           => $enable_network_service,
    install_service   => $enable_network_service,
    network_api_class	=> $network_api_class,
    quantum_url => $quantum_url,
    quantum_auth_strategy => $quantum_auth_strategy,
    quantum_admin_tenant_name => $quantum_admin_tenant_name,
    quantum_admin_username => $quantum_admin_username,
    quantum_admin_password => $quantum_admin_password,
    quantum_admin_auth_url => $quantum_admin_auth_url,
    libvirt_vif_driver => $libvirt_vif_driver,
    libvirt_use_virtio_for_bridges => $libvirt_use_virtio_for_bridges,
  }

  class { "quantum":
  enabled              => $quantum_enabled,
  package_ensure       => $quantum_package_ensure,
  log_verbose          => $quantum_log_verbose,
  log_debug            => $quantum_log_debug,
  bind_host            => $quantum_bind_host,
  bind_port            => $quantum_bind_port,
  sql_connection       => $quantum_sql_connection,
  auth_type            => $quantum_auth_strategy,
  auth_host            => $quantum_auth_host,
  auth_port            => $quantum_auth_port,
  auth_uri             => $quantum_admin_auth_url,
  keystone_tenant      => $quantum_admin_tenant_name,
  keystone_user        => $quantum_admin_username,
  keystone_password    => $quantum_admin_password,
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

class { "quantum::plugins::ovs":
    bridge_uplinks      => $ovs_bridge_uplinks,
    bridge_mappings      => $ovs_bridge_mappings,
    tenant_network_type  => $ovs_tenant_network_type,
    network_vlan_ranges  => $ovs_network_vlan_ranges,
    integration_bridge   => $ovs_integration_bridge,
    enable_tunneling    => $ovs_enable_tunneling,
    tunnel_bridge        => $ovs_tunnel_bridge,
    tunnel_id_ranges     => $ovs_tunnel_id_ranges,
    local_ip             => $ovs_local_ip,
    server               => $ovs_server,
    root_helper          => $ovs_root_helper,
    sql_connection       => $ovs_sql_connection,
  }


class { "quantum::rabbitmq":
  userid => $quantum_rabbit_user,
  password => $quantum_rabbit_password,
  port => $quantum_rabbit_port,
  virtual_host => $quantum_rabbit_virtual_host,
  enabled => true
}

class { "quantum::db::mysql":
  password      => $quantum_db_password, 
  dbname        => $quantum_db_name,
  user          => $quantum_db_user,
  host          => $quantum_db_host,
  allowed_hosts => $quantum_db_allowed_hosts,
  charset       => $quantum_db_charset,
  cluster_id    => $quantum_db_cluster_id,
}


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
  interface_driver         => $l3_interface_driver, 
  use_namespaces           => $l3_use_namespaces,
  router_id                => $router_id,
  gateway_external_net_id  => $gateway_external_net_id,
  metadata_ip              => $metadata_ip,
  external_network_bridge  => $external_network_bridge,
  root_helper              => $root_helper,
}


class {"quantum::agents::dhcp":
  state_path         => $dhcp_state_path,
  interface_driver   => $dhcp_interface_driver,
  dhcp_driver        => $dhcp_driver,
  use_namespaces     => $dhcp_use_namespaces,
  root_helper        => $dhcp_root_helper,
}

  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip':   value => 'True'; }
  }

  ######## Horizon ########

  # TOOO - what to do about HA for horizon?

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  class { 'horizon':
    secret_key => $secret_key,
    cache_server_ip => $cache_server_ip,
    cache_server_port => $cache_server_port,
    swift => $swift,
    quantum => $quantum,
    horizon_app_links => $horizon_app_links,
    horizon_top_links => $horizon_top_links,
  }


  ######## End Horizon #####

}
