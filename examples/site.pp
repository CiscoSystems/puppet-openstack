# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.

# Load apt prerequisites.  This is only valid on Ubuntu systems
class { 'apt': }

apt::ppa { 'ppa:cisco-openstack-mirror/cisco-proposed': }
apt::ppa { 'ppa:cisco-openstack-mirror/cisco': }

Apt::Ppa['ppa:cisco-openstack-mirror/cisco-proposed'] -> Package<| title != 'python-software-properties' |>
Apt::Ppa['ppa:cisco-openstack-mirror/cisco'] -> Package<| title != 'python-software-properties' |>

####### shared variables ##################
# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments
$multi_host	  	 = true
# assumes that eth0 is the public interface
$public_interface        = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface       = 'eth0.221'
# openstack::controller class assumes IP_addr_eth0. It is included here to be explicit.
$internal_address        = $ipaddress_eth0
# credentials
$admin_email             = 'root@localhost'
$admin_password          = 'Cisco123'
$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'
$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'
$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'
$glance_on_swift         = 'true'
$rabbit_password         = 'rabbit_password'
$rabbit_user             = 'rabbit_user'
$rabbit_addresses        = ['192.168.220.41','192.168.220.42','192.168.220.43']
$memcached_servers       = ['192.168.220.41:11211,192.168.220.42:11211,192.168.220.43:11211']
$fixed_network_range     = '10.0.0.0/24'
$floating_ip_range       = '192.168.220.96/27'
# switch this to true to have all service log at verbose
$verbose                 = 'false'
# by default it does not enable atomatically adding floating IPs
$auto_assign_floating_ip = true
# Swift addresses:
$swift_proxy_address    = '192.168.220.60'
# MySQL Information
$mysql_root_password    = 'ubuntu'
$mysql_puppet_password  = 'ubuntu'
$sql_connection = "mysql://nova:${nova_db_password}@${controller_node_address}/nova"
$horizon_secret_key     = 'elj1IWiLoWHgcyYxFVLj7cM5rGOOxWl0'
# RabbitMQ Cluster Configuration
$cluster_rabbit         = true
$rabbit_cluster_disk_nodes = ['control01', 'control02', 'control03']

#### end shared variables #################

# multi-controller deployment parameters

# The Virtual IP Address of the controller cluster
$controller_node_address       = '192.168.220.40'
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

# The Virtual Hostname of the controller cluster
$controller_hostname           = 'control'

# The actual address and hostname of the primary controller
$controller_node_primary       = '192.168.220.41'
$controller_hostname_primary   = 'control01'

# The actual address and hostname of the secondary controller
$controller_node_secondary     = '192.168.220.42'
$controller_hostname_secondary = 'control02'

# The actual address and hostname of the tertiary controller
$controller_node_tertiary     = '192.168.220.43'
$controller_hostname_tertiary = 'control03'

# The Virtual Swift Proxy Hostname and IP address
$swiftproxy_vip_hostname       = 'swiftproxy'
$swiftproxy_vip_address        = '192.168.220.60'

# The actual address and hostname of the primary swift proxy
$swiftproxy_ip_primary       = '192.168.220.52'
$swiftproxy_hostname_primary   = 'compute02'

# The actual address and hostname of the secondary swift proxy
$swiftproxy_ip_secondary     = '192.168.220.53'
$swiftproxy_hostname_secondary = 'compute03'

# /etc/hosts entries for the controller nodes
host { $controller_hostname_primary:
  ip => $controller_node_primary
}
host { $controller_hostname_secondary:
  ip => $controller_node_secondary
}
host { $controller_hostname_tertiary:
  ip => $controller_node_tertiary
}
host { $controller_hostname:
  ip => $controller_node_internal
}
host { $swiftproxy_hostname_primary:
  ip => $swiftproxy_ip_primary
}
host { $swiftproxy_hostname_secondary:
  ip => $swiftproxy_ip_secondary
}
host { $swiftproxy_vip_hostname:
  ip => $swiftproxy_vip_address
}
# include and load swift config and node definitions:
import 'swift-nodes'

# Load the cobbler node definitions needed for the preseed of nodes
import 'cobbler-node'

# Load the haproxy node definitions needed for load-balancing of Controller Nodes
import 'haproxy-nodes'

# Zero-out storage node disks
import 'clean-disk'

#Common configuration for all node compute, controller, storage but puppet-master/cobbler
node base {
 class { ntp:
    servers => [ "192.168.220.1" ],
    ensure => running,
    autoupdate => true,
  }
}

node /control01/ inherits base {

  # Configure /etc/network/interfaces file
  class { 'networking::interfaces':
    node_type           => controller,
    mgt_is_public       => true,
    vlan_networking     => true,
    vlan_interface      => "eth0",
    mgt_interface       => "eth0",
    mgt_ip              => "192.168.220.41",
    mgt_gateway         => "192.168.220.1",
    flat_vlan           => "221",
    flat_ip 		=> "10.0.0.251",
    dns_servers         => "192.168.220.254",
    dns_search          => "dmz-pod2.lab",
 }

  class { 'galera' :
        cluster_name            => 'openstack',
	# uncomment the master_ip parameter after the 2nd controller is operational. Make sure to recomment if you rebuild the node.
        #master_ip               => $controller_node_secondary,    
}

  class {'galera::haproxy': }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    virtual_address         => $controller_node_address,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $internal_address,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_host           => $controller_node_address,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    glance_on_swift         => $glance_on_swift,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    horizon_secret_key	    => $horizon_secret_key,
    memcached_servers       => $memcached_servers,
    cache_server_ip         => $internal_address,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    cluster_rabbit          => $cluster_rabbit,
    cluster_disk_nodes      => $rabbit_cluster_disk_nodes,
    api_bind_address        => $internal_address,
    export_resources        => false,
    enabled                 => true, #different between active and passive.
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

  # Temp disabled to test manifests
  class { 'swift::keystone::auth':
    auth_name => $swift_user,
    password => $swift_user_password,
    address  => $swift_proxy_address,
  }

  #Needed to address a nova-consoleauth limitation for HA - bug has been filed
  class { 'nova::consoleauth::ha_patch': }

}

node /control02/ inherits base {

  # Configure /etc/network/interfaces file
  class { 'networking::interfaces':
    node_type           => controller,
    mgt_is_public       => true,
    vlan_networking     => true,
    vlan_interface      => "eth0",
    mgt_interface       => "eth0",
    mgt_ip              => "192.168.220.42",
    mgt_gateway         => "192.168.220.1",
    flat_vlan           => "221",
    flat_ip             => "10.0.0.252",
    dns_servers         => "192.168.220.254",
    dns_search          => "dmz-pod2.lab",
 }

  class { 'galera' :
        cluster_name            => 'openstack',
        master_ip               => $controller_node_primary,  
  }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    virtual_address         => $controller_node_address,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $internal_address,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_host           => $controller_node_address,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    glance_on_swift         => $glance_on_swift,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    horizon_secret_key      => $horizon_secret_key,
    memcached_servers       => $memcached_servers,
    cache_server_ip         => $internal_address,   
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    cluster_rabbit          => $cluster_rabbit,
    cluster_disk_nodes      => $rabbit_cluster_disk_nodes,
    api_bind_address        => $internal_address,
    export_resources        => false,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

  #Needed to address a nova-consoleauth limitation for HA - bug has been filed
  class { 'nova::consoleauth::ha_patch': }

}

node /control03/ inherits base {

  # Configure /etc/network/interfaces file
  class { 'networking::interfaces':
    node_type           => controller,
    mgt_is_public       => true,
    vlan_networking     => true,
    vlan_interface      => "eth0",
    mgt_interface       => "eth0",
    mgt_ip              => "192.168.220.43",
    mgt_gateway         => "192.168.220.1",
    flat_vlan           => "221",
    flat_ip             => "10.0.0.253",
    dns_servers         => "192.168.220.254",
    dns_search          => "dmz-pod2.lab",
 }

  class { 'galera' :
        cluster_name            => 'openstack',
        master_ip               => $controller_node_primary,  
  }

  class { 'openstack::controller':
    public_address          => $controller_node_public,
    virtual_address         => $controller_node_address,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $internal_address,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    admin_email             => $admin_email,
    admin_password          => $admin_password,
    keystone_host           => $controller_node_address,
    keystone_db_password    => $keystone_db_password,
    keystone_admin_token    => $keystone_admin_token,
    glance_db_password      => $glance_db_password,
    glance_user_password    => $glance_user_password,
    glance_on_swift         => $glance_on_swift,
    nova_db_password        => $nova_db_password,
    nova_user_password      => $nova_user_password,
    horizon_secret_key      => $horizon_secret_key,
    memcached_servers       => $memcached_servers,
    cache_server_ip         => $internal_address,   
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    cluster_rabbit          => $cluster_rabbit,
    cluster_disk_nodes      => $rabbit_cluster_disk_nodes,
    api_bind_address        => $internal_address,
    export_resources        => false,
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

  #Needed to address a nova-consoleauth limitation for HA - bug has been filed
  class { 'nova::consoleauth::ha_patch': }

}

node /compute01/ inherits base {

  # Configure /etc/network/interfaces file
  class { 'networking::interfaces':
    node_type           => compute,
    mgt_is_public       => true,
    vlan_networking     => true,
    vlan_interface      => "eth0",
    mgt_interface       => "eth0",
    mgt_ip              => "192.168.220.51",
    mgt_gateway         => "192.168.220.1",
    flat_vlan           => "221",
    dns_servers         => "192.168.220.254",
    dns_search          => "dmz-pod2.lab",
 }

  #Needed to address a short term failure in nova-volume management - bug has been filed
  class { 'nova::compute::file_hack': }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

  class { 'openstack::compute':
    public_interface   => $public_interface,
    private_interface  => $private_interface,
    internal_address   => $internal_address,
    virtual_address    => $controller_node_address,
    libvirt_type       => 'kvm',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    multi_host         => $multi_host,
    nova_user_password => $nova_user_password,
    nova_db_password   => $nova_db_password,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    api_bind_address   => $internal_address,    
    vncproxy_host      => $controller_node_address,
    vnc_enabled        => 'true',
    verbose            => $verbose,
    manage_volumes     => true,
    nova_volume        => 'nova-volumes',
  }
}

node /build-os/ inherits "cobbler-node" {
 
 #change the servers for your NTP environment
  class { ntp:
    servers => [ "192.168.220.1"],
    ensure => running,
    autoupdate => true,
  }

  # set up a local apt cache.  Eventually this may become a local mirror/repo instead
  class { apt-cacher-ng:
    }

# set the right local puppet environment up.  This builds puppetmaster with storedconfigs (a nd a local mysql instance)
  class { puppet:
    run_master => true,
    mysql_password => $mysql_puppet_password,
    mysql_root_password => $mysql_root_password,
  }<-
  file {'/etc/puppet/files':
    ensure => directory,
    owner => 'root',
    group => 'root',
    mode => '0755',
  }

  file {'/etc/puppet/fileserver.conf':
    ensure => file,
    owner => 'root',
    group => 'root',
    mode => '0644',
    content => '

# This file consists of arbitrarily named sections/modules
# defining where files are served from and to whom

# Define a section "files"
# Adapt the allow/deny settings to your needs. Order
# for allow/deny does not matter, allow always takes precedence
# over deny
[files]
  path /etc/puppet/files
  allow *
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24

[plugins]
#  allow *.example.com
#  deny *.evil.example.com
#  allow 192.168.0.0/24
',
  }
}

node default {
  notify{"Default Node: Perhaps add a node definition to site.pp": }
}
