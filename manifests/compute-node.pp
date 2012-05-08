class openstack::compute-node(
	$mysql_root_password = 'UbQuaiwenn2',
	$nova_db_password = 'gjD4sFJuds',
	$ip = "${ipaddress_eth0}",
	$bridge_ip = '192.168.188.1',
	$bridge_netmask = '255.255.255.0',
	$glance_api_servers = '127.0.0.1:9292',
	$network_manager = 'nova.network.manager.FlatDHCPManager',
	$cluster_id = 'localzone') {

	# MySQL server
	class { 'mysql::python': }

	# Nova
	Nova_config<<| title == "rabbit_host" |>>
	Nova_config<<| title == "sql_connection" |>>

	class { nova:
		image_service  => 'nova.image.glance.GlanceImageService',
		glance_api_servers => $glance_api_servers,
		network_manager => $network_manager,
	}

	class { nova::compute:
		enabled => true
	}

	@@nova::db::mysql::host_access { $ip:
		user => 'nova',
		password => $nova_db_password,
		database => 'nova',
		tag => $cluster_id
	}
}
