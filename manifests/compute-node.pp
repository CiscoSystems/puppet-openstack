class openstack::compute-node(
	$mysql_root_password = 'UbQuaiwenn2',
	$nova_db_password = 'gjD4sFJuds',
	$ip = "${ipaddress_eth0}",
	$bridge_ip = '192.168.188.1',
	$bridge_netmask = '255.255.255.0',
	$glance_api_servers = '127.0.0.1:9292',
	$mysql_ip = '127.0.0.',
	$network_manager = 'nova.network.manager.FlatDHCPManager') {

	# MySQL server
	class { 'mysql::python': }

	# Nova
	Nova_config<<| title == "rabbit_host" |>>

	class { nova:
		sql_connection => "mysql://nova:${nova_db_password}@${mysql_ip}/nova",
		image_service  => 'nova.image.glance.GlanceImageService',
		glance_api_servers => $glance_api_servers,
		network_manager => $network_manager,
		admin_password => $nova_service_password,
	}

	class { nova::compute:
		enabled => true }

	class { nova::compute::libvirt:
		flat_network_bridge_ip => $bridge_ip,
		flat_network_bridge_netmask => $bridge_netmask,
	}

	@@nova::db::mysql::host_access { $ip:
		user => 'nova',
		password => $nova_db_password,
		database => 'nova'
	}
}
