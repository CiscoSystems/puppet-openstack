# This is a work in progress site.pp for an OpenStack HA environment.
# If you have an existing site.pp, back it up first.
# Edit and copy to /etc/puppet/manifests/site.pp
# This document serves as an example of how to deploy
# basic single and multi-node openstack environments.

# Load apt prerequisites.  This is only valid on Ubuntu systmes
# Temp disabled due to HA troubleshooting
#class { 'apt': }

#apt::ppa { 'ppa:cisco-openstack-mirror/cisco-proposed': }
#apt::ppa { 'ppa:cisco-openstack-mirror/cisco': }

#Apt::Ppa['ppa:cisco-openstack-mirror/cisco-proposed'] -> Package<| title != 'python-software-properties' |>
#Apt::Ppa['ppa:cisco-openstack-mirror/cisco'] -> Package<| title != 'python-software-properties' |>

####### shared variables ##################
# this section is used to specify global variables that will
# be used in the deployment of multi and single node openstack
# environments
$multi_host		= true
# assumes that eth0 is the public interface
$public_interface        = 'eth0'
# assumes that eth1 is the interface that will be used for the vm network
# this configuration assumes this interface is active but does not have an
# ip address allocated to it.
$private_interface       = 'eth0.221'
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
# Temp disabled for HA troubleshooting defaults to guest
#$rabbit_password         = 'openstack_rabbit_password'
#$rabbit_user             = 'openstack_rabbit_user'
$fixed_network_range     = '192.168.16.0/20'
$floating_ip_range       = '162.150.10.0/23'
# switch this to true to have all service log at verbose
$verbose                 = 'false'
# Swift addresses:
$swift_proxy_address    = '$SWIFT_PROXY_VIP'
# MySQL Information
$mysql_root_password    = 'ubuntu'
$mysql_puppet_password  = 'ubuntu'
$sql_connection = "mysql://nova:${nova_db_password}@${controller_node_address}/nova"
# Horizon secret key in local_settinga.py
$horizon_secret_key     = 'horizon_secret_key'
#### end shared variables #################

# multi-node specific parameters

# The address services will attempt to connect to the controller with
$controller_node_address       = '$CTRL_VIP'
$controller_node_public        = $controller_node_address
$controller_node_internal      = $controller_node_address

# The hostname other nova nodes see the controller as
$controller_hostname           = 'control'

# The actual address of the primary/active controller
$controller_node_primary       = '$CTRL_PRIME'
$controller_hostname_primary   = 'control01'

# The actual address of the secondary/passive controller
$controller_node_secondary     = '$CTRL_SEC'
$controller_hostname_secondary = 'control02'

# The actual address of the secondary/passive controller
$controller_node_tertiary     = '$CTRL_THIRD'
$controller_hostname_tertiary = 'control03'

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

# include and load swift config and node definitions:
import 'swift-nodes'

# Load the cobbler node definitions needed for the preseed of nodes
import 'cobbler-node'

# export an authorized keys file to the root user of all nodes.
# This is most useful for testing.
#import 'ssh-keys'
#import 'clean-disk'
#Common configuration for openstack nodes compute, controller, storage but not puppet-master/cobbler
node base {
 class { ntp:
    servers => [ "$NTP_SERVER_IP" ],
    ensure => running,
    autoupdate => true,
  }
}

node compute_base inherits base {
#  class { 'collectd':
#  }
}

node /$HAPROXY_NODE1/ inherits base {

 sysctl::value { "net.ipv4.ip_nonlocal_bind": value => "1" }

 class { keepalived: }
  keepalived::instance { '50':
   interface         => 'eth0',
   virtual_ips       => [ '$CTRL_VIP dev eth0' ],
   state             => 'MASTER',
   priority          => '101',
 }

 class { 'haproxy':
   enable                   => true,
   
   haproxy_global_options   => { 'log'     => "${::ipaddress} local0",
                                 'pidfile' => '/var/run/haproxy.pid',
                                 'maxconn' => '4096',
                                 'user'    => 'haproxy',
                                 'group'   => 'haproxy',
                                 'daemon'  => '',},
   
   haproxy_defaults_options => { 'log'     => 'global',
                                 'mode'    => 'http',
                                 'option'  => ['dontlognull','redispatch','tcplog'],
                                 'retries' => '3',
                                 'timeout' => ['http-request 10s',
                                                 'queue 1m',
                                                 'connect 10s',
                                                 'client 1m',
                                                 'server 1m',
                                                 'check 10s'],
                                 'maxconn' => '4096'},
  }

 haproxy::config { 'galera_cluster':
    order                  	=> '20',
    virtual_ip             	=> '$CTRL_VIP',
    virtual_ip_port        	=> ['3306'],
    haproxy_config_options 	=> {'mode' => 'tcp','option' => ['tcpka', 'httpchk', 'mysql-check user haproxy'],'balance' => 'source'},
  }

 Haproxy::Balancermember <<| listening_service == 'galera_cluster' |>>

}

node /$HAPROXY_NODE2/ inherits base {

 sysctl::value { "net.ipv4.ip_nonlocal_bind": value => "1" }

 class { keepalived: }
  keepalived::instance { '50':
   interface         => 'eth0',
   virtual_ips       => [ '$CTRL_VIP dev eth0' ],
   state             => 'BACKUP',
   priority          => '100',
 }

class { 'haproxy':
   enable                   => true,

   haproxy_global_options   => { 'log'     => "${::ipaddress} local0",
                                 'pidfile' => '/var/run/haproxy.pid',
                                 'maxconn' => '4096',
                                 'user'    => 'haproxy',
                                 'group'   => 'haproxy',
                                 'daemon'  => '',},

   haproxy_defaults_options => { 'log'     => 'global',
                                 'mode'    => 'http',
                                 'option'  => ['dontlognull','redispatch','tcplog'],
                                 'retries' => '3',
                                 'timeout' => ['http-request 10s',
                                                 'queue 1m',
                                                 'connect 10s',
                                                 'client 1m',
                                                 'server 1m',
                                                 'check 10s'],
                                 'maxconn' => '4096'},
  }

 haproxy::config { 'galera_cluster':
    order                       => '20',
    virtual_ip                  => '$CTRL_VIP',
    virtual_ip_port             => ['3306'],
    haproxy_config_options      => {'mode'   	=> 'tcp',
				    'option' 	=> ['tcpka', 'httpchk', 'mysql-check user haproxy'],
				    'balance' 	=> 'source'},
   }

 Haproxy::Balancermember <<| listening_service == 'galera_cluster' |>>

}

node /$CTRL1/ inherits base {

  class { 'galera' :
        cluster_name            => 'openstack',
	    #master_ip              => $controller_node_secondary,
    }

  @@haproxy::balancermember { $fqdn:
    listening_service      => 'controller_cluster',
    balancer_port          => ['3306'],
    order                  => '21',
    server_name            => $::hostname,
    balancer_ip            => $::ipaddress,
    balancermember_options => 'weight 1',
  }

  class {'galera::haproxy': }

  class { 'openstack::controller_master':
    public_address          => $controller_node_public,
    virtual_address         => $controller_node_address,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_primary,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    #mysql_root_password     => $mysql_root_password,
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
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    # Req for HA Phase 2 Nova Module
    api_bind_address        => $ipaddress_eth0,
    export_resources        => true,
    enabled                 => true, #different between active and passive.
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

  class { 'swift::keystone::auth':
    auth_name => $swift_user,
    password => $swift_user_password,
    address  => $swift_proxy_address,
  }

}

node /CTRL2/ inherits base {

  class { 'galera' :
        cluster_name            => 'openstack',
        master_ip               => $controller_node_primary,  
  }

  @@haproxy::balancermember { $fqdn:
    listening_service      => 'controller_cluster',
    balancer_port          => ['3306'],
    order                  => '22',
    server_name            => $::hostname,
    balancer_ip            => $::ipaddress,
    balancermember_options => 'weight 1',
  }

  class { 'openstack::controller_slave':
    public_address          => $controller_node_public,
    virtual_address         => $controller_node_address,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_secondary,
    #service_bind_address    => $ipaddress_eth0,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    #mysql_root_password     => $mysql_root_password,
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
    rabbit_host             => $controller_node_primary,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    # Req for HA Phase 2 Nova Module
    api_bind_address        => $ipaddress_eth0,
    export_resources        => false,
    enabled                 => true, #different between active and passive.
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

}

node /CTRL3/ inherits base {

  class { 'galera' :
        cluster_name            => 'openstack',
        master_ip               => $controller_node_primary,  
  }

  @@haproxy::balancermember { $fqdn:
    listening_service      => 'controller_cluster',
    balancer_port          => ['3306'],
    order                  => '22',
    server_name            => $::hostname,
    balancer_ip            => $::ipaddress,
    balancermember_options => 'weight 1',
  }

  class { 'openstack::controller_slave':
    public_address          => $controller_node_public,
    virtual_address         => $controller_node_address,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_secondary,
    #service_bind_address    => $ipaddress_eth0,
    floating_range          => $floating_ip_range,
    fixed_range             => $fixed_network_range,
    # by default it does not enable multi-host mode
    multi_host              => $multi_host,
    # by default is assumes flat dhcp networking mode
    network_manager         => 'nova.network.manager.FlatDHCPManager',
    verbose                 => $verbose,
    auto_assign_floating_ip => $auto_assign_floating_ip,
    #mysql_root_password     => $mysql_root_password,
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
    rabbit_host             => $controller_node_primary,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    # Req for HA Phase 2 Nova Module
    api_bind_address        => $ipaddress_eth0,
    export_resources        => false,
    enabled                 => true, #different between active and passive.
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }

}


node /$COMPUTE/ inherits compute_base {

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
    internal_address   => $ipaddress_eth0,
    libvirt_type       => 'kvm',
    fixed_range        => $fixed_network_range,
    network_manager    => 'nova.network.manager.FlatDHCPManager',
    multi_host         => $multi_host,
    #sql_connection     => $sql_connection,
    nova_user_password => $nova_user_password,
    rabbit_host        => $controller_node_primary,
    rabbit_password    => $rabbit_password,
    rabbit_user        => $rabbit_user,
    glance_api_servers => "192.168.220.40:9292",
    api_bind_address   => $ipaddress_eth0,    
    vncproxy_host      => $controller_node_address,
    vnc_enabled        => 'true',
    verbose            => $verbose,
    manage_volumes     => true,
    nova_volume        => 'nova-volumes',
  }

}

##### EDIT THIS SECTION ##############
node /$BUILD_NODE/ inherits "cobbler-node" {
 
#import "glance_download"

#change the servers for your NTP environment
  class { ntp:
    servers => [ "$NTP_IP"],
    ensure => running,
    autoupdate => true,
  }

# set up a local apt cache.  Eventually this may become a local mirror/repo instead
  class { apt-cacher-ng:
    }

# set the right local puppet environment up.  This builds puppetmaster with storedconfigs (and a local mysql instance)
  class { puppet:
    run_master => true,
#    puppetmaster_address => $::fqdn,
#    certname => '$PUPPET_CERT_NAME',
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
