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
# [virtual_address] Virtual IP Address used for HA. Required.
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
  $virtual_address,
  $public_interface,
  $private_interface,
  $internal_address,
  $admin_address           = $internal_address,
  $api_bind_address        = '0.0.0.0',
  #$service_bind_address    = '127.0.0.1',
  # connection information
  $mysql_root_password     = 'sql_pass',
  $admin_email             = 'some_user@some_fake_email_address.foo',
  $admin_password          = 'ChangeMe',
  $keystone_host           = '127.0.0.1',
  $keystone_db_password    = 'keystone_pass',
  $keystone_admin_token    = 'keystone_admin_token',
  $glance_db_password      = 'glance_pass',
  $glance_user_password    = 'glance_pass',
  $nova_db_password        = 'nova_pass',
  $nova_user_password      = 'nova_pass',
  #$rabbit_host             = '192.168.220.41',
  $rabbit_password         = 'rabbit_pw',
  $rabbit_user             = 'nova',
  $rabbit_addresses,
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
  $memcached_servers       = $memcached_servers,
  $cache_server_ip         = '127.0.0.1',
  $cache_server_port       = '11211',
  $swift                   = false,
  $glance_on_swift	   = false,
  $quantum                 = false,
  $horizon_secret_key      = 'horizon_secret_key',
  #$horizon_app_links       = false,
  #$horizon_top_links       = false,
  $enabled                 = true
) {

  $glance_api_servers = "${virtual_address}:9292"
  $nova_db = "mysql://nova:${nova_db_password}@${virtual_address}/nova"

  if ($export_resources) {
    # export all of the things that will be needed by the clients
    @@nova_config { 'rabbit_host': value => $internal_address }
    Nova_config <| title == 'rabbit_addresses' |>
    @@nova_config { 'sql_connection': value => $nova_db }
    Nova_config <| title == 'sql_connection' |>
    @@nova_config { 'glance_api_servers': value => $glance_api_servers }
    Nova_config <| title == 'glance_api_servers' |>
    @@nova_config { 'novncproxy_base_url': value => "http://${virtual_address}:6080/vnc_auto.html" }
    $sql_connection    = false
    $glance_connection = false
    #$rabbit_connection = false
  } else {
    $sql_connection    = $nova_db
    $glance_connection = $glance_api_servers
    #$rabbit_connection = $internal_address
  }

  ####### DATABASE SETUP ######

  # set up mysql server
  if (!defined(Class[galera])) {
    class { 'galera':
      enabled => $enabled,
    }
  }
  if ($enabled) {
    # set up all openstack databases, users, grants
    class { 'keystone::db::mysql':
      password => $keystone_db_password,
      host     => $virtual_address,
      allowed_hosts => '%',
    }
    Class['glance::db::mysql'] -> Class['glance::registry']
    class { 'glance::db::mysql':
      password => $glance_db_password,
      host     => $virtual_address,
      allowed_hosts => '%',
    }
    # TODO should I allow all hosts to connect?
    class { 'nova::db::mysql':
      password      => $nova_db_password,
      host          => $virtual_address,
      allowed_hosts => '%',
    }
  }

  ####### KEYSTONE ###########

  # set up keystone
  class { 'keystone':
    admin_token  => $keystone_admin_token,
    # we are binding keystone on all interfaces
    # the end user may want to be more restrictive
    bind_host    => $internal_address,
    log_verbose  => $verbose,
    log_debug    => $verbose,
    catalog_type => 'sql',
    enabled      => $enabled,
  }
  # set up keystone database
  # set up the keystone config for mysql
  class { 'keystone::config::mysql':
    password => $keystone_db_password,
    host     => $virtual_address,
  }
  
  if ($enabled) {
    # set up keystone admin users
    class { 'keystone::roles::admin':
      email    => $admin_email,
      password => $admin_password,
    }
    # set up the keystone service and endpoint
    class { 'keystone::endpoint':
      public_address   => $virtual_address,
      internal_address => $virtual_address,
      admin_address    => $virtual_address,
    }
    # set up glance service,user,endpoint
    class { 'glance::keystone::auth':
      password         => $glance_user_password,
      public_address   => $virtual_address,
      internal_address => $virtual_address,
      admin_address    => $virtual_address,
      before           => [Class['glance::api'], Class['glance::registry']]
    }
    # set up nova serice,user,endpoint
    class { 'nova::keystone::auth':
      password         => $nova_user_password,
      public_address   => $virtual_address,
      internal_address => $virtual_address,
      admin_address    => $virtual_address,
      before           => Class['nova::api'],
    }
  }

  ######## END KEYSTONE ##########

  ######## BEGIN GLANCE ##########


  class { 'glance::api':
    bind_host         => $internal_address,
    registry_host     => $virtual_address,
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_host         => $virtual_address,
    auth_port         => '35357',
    auth_protocol     => 'http',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    enabled           => $enabled,
  }
  if $glance_on_swift {
    class { 'glance::backend::swift':
      swift_store_user => 'openstack:admin',
      swift_store_key => $admin_password,
      swift_store_auth_address => "http://${virtual_address}:5000/v2.0/",
      swift_store_container => 'glance',
      swift_store_create_container_on_put => 'true'
    }
  } else {
    class { 'glance::backend::file': }
  }
  class { 'glance::registry':
    bind_host         => $internal_address,
    log_verbose       => $verbose,
    log_debug         => $verbose,
    auth_type         => 'keystone',
    auth_protocol     => 'http',
    auth_host         => $virtual_address,
    auth_port         => '35357',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    sql_connection    => "mysql://glance:${glance_db_password}@${virtual_address}/glance",
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
    #rabbit_host        => $rabbit_connection,
    #rabbit_host        => $rabbit_host,
    rabbit_userid      => $rabbit_user,
    rabbit_password    => $rabbit_password,
    rabbit_addresses   => $rabbit_addresses,
    image_service      => 'nova.image.glance.GlanceImageService',
    glance_api_servers => $glance_connection,
    #memcached_servers  => $memcached_servers,
    verbose            => $verbose,
  }

  class { 'nova::consoleauth':
    enabled            => $enabled,
    memcached_servers  => $memcached_servers,
  }

  class { 'nova::api':
    enabled         	=> $enabled,
    admin_tenant_name 	=> 'services',
    admin_user        	=> 'nova',
    admin_password    	=> $nova_user_password,
    auth_host         	=> $virtual_address,
    api_bind_address    => $api_bind_address,
}

  class { [
    'nova::scheduler',
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
  }

  if $auto_assign_floating_ip {
    nova_config { 'auto_assign_floating_ip':   value => 'True'; }
  }

  ######## Horizon ########

  # TOOO - what to do about HA for horizon?

  class { 'memcached':
    listen_ip => $cache_server_ip,
  }

  class { 'horizon':
    secret_key		=> $horizon_secret_key,
    cache_server_ip   	=> $cache_server_ip,
    cache_server_port 	=> $cache_server_port,
    keystone_host     	=> $keystone_host, 
    swift 		=> $swift,
    quantum 		=> $quantum,
  }


  ######## End Horizon #####

}
