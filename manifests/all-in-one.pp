# = Class: openstack::all-in-one
# 
# == Parameters:
# - mysql_root_password			Password for the mysql"root" user on the database host(s)
# - mysql_host							Hostname (or IP) for the Mysql server
# - keystone_db_password		Password for the Keystone db (on the mysql server)
# - keystone_admin_token		Administration token for Keystone access
# - glance_db_passwrod			Password for the Glance db (on the mysql server)
# - glance_servcie_password	Password for access to the Glance service
# - glance_host							Hostname (or IP) for the Glance server
# - nova_db_password				Password for the Nova db (on the mysql server)
# - nova_service_password		Password for access to the Nova service
# - nova_host								Hostname (or IP) for the Nova server
# - admin_password					Password for the Admin user
# - bridge_ip								IP for the nova compute Bridge interface ("inside")
# - bridge_netmask					Netmask for the Bridge interface
# - public_ip								IP for the public facing interface ("outside")
# - admin_ip								IP for administration of the system
# - internal_ip							IP for loopback
# - network_manager					Network manager type (VLAN, Flat, FlatDHCP, Quantum)
# 
# == Example:
# 
# A basic node definition
#
# node /nova\.example\.com/ {
# 	class { "openstack::all-in-one":
# 	}
# }
# 
# Or a set up with a specific bridge interface, and the host addresses exposed on the external network, likley to allow for adding compute nodes.
# 
# node /nova\.example\.com/ {
# 	class { "openstack::all-in-one":
# 		bridge_ip => '192.168.200.1',
# 		mysql_host => $ip_address,
# 		glance_host => $ip_address,
# 		nova_host => $ip_address,
# 	}
# }
# 
# 
class openstack::all-in-one(
	$mysql_root_password = 'UbQuaiwenn2',
	$keystone_db_password = 'Peffyuc5',
	$keystone_admin_token = 'TucMidIvtob2',
	$glance_db_password = 'oidf73DFE',
	$glance_service_password = '55kdiRbWE',
	$glance_host = 'localhost',
	$nova_db_password = 'gjD4sFJuds',
	$nova_service_password = 'dk33fWEee',
	$nova_host = 'localhost',
	$admin_password = '4dmin',
	$bridge_ip = '192.168.188.1',
	$bridge_netmask = '255.255.255.0',
	$public_ip = "$ipaddress",
	$admin_ip = "$ipaddress",
	$internal_ip = "$ipaddress",
	$network_manager = 'nova.network.manager.FlatDHCPManager') {

	# MySQL server
	class { 'mysql::server':
		config_hash => {
			'root_password' => $mysql_root_password,
			'bind_address' => '0.0.0.0' }
	}

	# Keystone Server

	# Sets up the Keystone DB
	class { 'keystone::db::mysql':
		password => $keystone_db_password,
	}

	# Configures Keystone to use the above DB
	class { 'keystone::config::mysql':
		password => $keystone_db_password,
	}

	class { 'keystone':
		admin_token => $keystone_admin_token,
		log_verbose	=> true,
		log_debug		=> true,
		catalog_type => 'sql',
	}

	# Set up an admin user
	class { 'keystone::roles::admin':
		password => $admin_password
	}

	class { 'keystone::endpoint': }

	# Glance
	class { 'glance::keystone::auth':
		password => $glance_service_password,
		address => $public_ip,
	}

	class { glance::db::mysql:
		password => $glance_db_password
	}

	class { glance::api:
		auth_type => 'keystone',
		auth_host => '127.0.0.1',
		auth_port => '35357',
		keystone_tenant => 'services',
		keystone_user => 'glance',
		keystone_password => $glance_service_password,
	}

	class { glance::registry:
		auth_type => 'keystone',
		auth_host => '127.0.0.1',
		auth_port => '35357',
		keystone_tenant => 'services',
		keystone_user => 'glance',
		keystone_password => $glance_service_password,
		sql_connection => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
	}

	class { glance::backend::file: }

	# Nova
	class { 'nova::keystone::auth':
		password => $nova_service_password,
		public_address => $public_ip,
	}

	class { nova::rabbitmq: }

	class { nova::db::mysql:
		password => $nova_db_password,
		host => 'localhost',
	}

	class { 'nova':
		sql_connection => "mysql://nova:${nova_db_password}@${mysql_host}/nova",
		image_service	=> 'nova.image.glance.GlanceImageService',
		glance_api_servers => '127.0.0.1:9292',
		network_manager => $network_manager,
	}

	class { 'nova::api':
		enabled => true,
		admin_password => $nova_service_password
	}

	class { 'nova::scheduler':
		enabled => true
	}

	class { 'nova::network':
		enabled => true
	}

	nova::manage::network { "nova-vm-net":
		network => '192.168.188.0/24',
		available_ips => '256',
	}

	class { 'nova::objectstore':
		enabled => true
	}

	class { 'nova::volume':
		enabled => true
	}

	class { 'nova::compute':
		enabled											 => true,
		vnc_enabled									 => true,
		vncserver_proxyclient_address => '127.0.0.1',
		vncproxy_host								 => $ipaddress,
	}

	class { 'nova::cert':
		enabled => true
	}

	class { 'nova::consoleauth':
		enabled => true
	}

	class { 'nova::compute::libvirt':
		libvirt_type		 => 'kvm',
		vncserver_listen => '127.0.0.1',
#		flat_network_bridge_ip => $bridge_ip,
#		flat_network_bridge_netmask => $bridge_netmask,
	}

	class { 'memcached':
		listen_ip => '127.0.0.1',
	}

	class { 'horizon': }

	######## End Horizon #####
	#
	# Clear out any settings from nova's config that we didn't put there
	resources { 'nova_config':
		purge => true,
	}
}
