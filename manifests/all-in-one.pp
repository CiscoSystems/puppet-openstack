class openstack::all-in-one(
	$mysql_root_password = 'UbQuaiwenn2',
	$keystone_db_password = 'Peffyuc5',
	$keystone_admin_token = 'TucMidIvtob2',
	$glance_db_password = 'oidf73DFE',
	$glance_service_password = '55kdiRbWE',
	$nova_db_password = 'gjD4sFJuds',
	$nova_service_password = 'dk33fWEee',
	$admin_password = '4dmin',
	$bridge_ip = '192.168.188.1',
	$bridge_netmask = '255.255.255.0',
	$public_ip = "$ipaddress",
	$admin_ip = "$ipaddress",
	$internal_ip = "$ipaddress",
	$network_manager = 'nova.network.manager.FlatDHCPManager') {

	# MySQL server
	class { 'mysql::python': }
	class { 'mysql::server':
		config_hash => {
			'root_password' => $mysql_root_password,
			'bind_address' => '0.0.0.0' }
	}

	# Keystone Server
	class { 'keystone::mysql':
		password => $keystone_db_password,
	}
	class { 'keystone::config::mysql':
		password => $keystone_db_password,
	}
	class { 'keystone':
		admin_token => $keystone_admin_token,
		log_verbose  => true,
		log_debug    => true,
		catalog_type => 'sql',
	}

	keystone_service { "keystone":
		ensure => present,
		type => "identity",
		description => "OpenStack Identity Service"
	}

	keystone_endpoint { "keystone":
		ensure => present,
		public_url => "http://${public_ip}:5000/v2.0",
		admin_url => "http://${admin_ip}:35357/v2.0",
		internal_url => "http://${internal_ip}:5000/v2.0"
	}

	# Keystone tenant for services
	keystone_tenant { "services":
		ensure => present
	}

	keystone_role { "admin":
		ensure => present
	}

	# Glance
	class { glance::db:
		password => $glance_db_password
	}

	class { glance::registry:
		keystone_tenant => 'services',
		keystone_user => 'glance',
		keystone_password => $glance_service_password,
		sql_connection => "mysql://glance:${glance_db_password}@127.0.0.1/glance",
		require => [Class[glance::db], Keystone_user_role["glance@services"]]
	}

	class { glance::api:
		keystone_tenant => 'services',
		keystone_user => 'glance',
		keystone_password => $glance_service_password,
		require => Keystone_user_role["glance@services"]
	}

	class { glance::backend::file: }

	keystone_service { "glance":
		ensure => present,
		type => "image",
		description => "OpenStack Image Service"
	}

	keystone_endpoint { "glance":
		ensure => present,
		public_url => "http://${public_ip}:9292/v1",
		admin_url => "http://${admin_ip}:9292/v1",
		internal_url => "http://${internal_ip}:9292/v1"
	}

	keystone_user { "glance":
		password => $glance_service_password,
		ensure => present
	}

	keystone_user_role { "glance@services":
		roles => ["admin"]
	}
	

	# Nova
	class { nova::rabbitmq: }

	class { nova::db:
		password => $nova_db_password,
		host => 'localhost',
	}

	class { nova:
		sql_connection => "mysql://nova:${nova_db_password}@localhost/nova",
		image_service  => 'nova.image.glance.GlanceImageService',
		glance_api_servers => '127.0.0.1:9292',
		network_manager => $network_manager,
		admin_password => $nova_service_password,
	}

	class { nova::api:
		enabled => true,
		require => Keystone_user_role["nova@services"]
	}

	class { nova::scheduler:
		enabled => true
	}

	class { nova::network:
		enabled => true
	}

	class { nova::objectstore:
		enabled => true
	}

	class { nova::compute:
		enabled => true }

	class { nova::compute::libvirt:
		flat_network_bridge_ip => $bridge_ip,
		flat_network_bridge_netmask => $bridge_netmask,
	}

	keystone_service { "nova":
		ensure => present,
		type => "compute",
		description => "OpenStack Compute Service"
	}

	keystone_endpoint { "nova":
		ensure => present,
		public_url => "http://${public_ip}:8774/v1.1/%(tenant_id)s",
		admin_url => "http://${admin_ip}:8774/v1.1/%(tenant_id)s",
		internal_url => "http://${internal_ip}:8774/v1.1/%(tenant_id)s"
	}

	keystone_user { "nova":
		ensure => present,
		password => $nova_service_password
	}

	keystone_user_role { "nova@services":
		roles => ["admin"]
	}


	#
	# Users
	# 
	keystone_tenant { "users":
		ensure => present
	}

	keystone_user { "admin":
		ensure => present,
		password => $admin_password
	}

	keystone_role { "member":
		ensure => present
	}

	keystone_user_role { "admin@users":
		roles => ["member"]
	}

	resources { 'nova_config':
		purge => true,
	}
}
