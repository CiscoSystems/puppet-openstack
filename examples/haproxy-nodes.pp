# This file is used to define dedicated HAproxy nodes for load-balancing 3 OpenStack Controller Nodes

node /swiftproxy01/ inherits base {

  # Configure /etc/network/interfaces file
  class { 'networking::interfaces':
  # Node Types: controller, compute, swift-proxy, swift-storage, or load-balancer
   node_type           => load-balancer,
   mgt_is_public       => true,
   mgt_interface       => "eth0",
   mgt_ip              => "192.168.220.61",
   mgt_gateway         => "192.168.220.1",
   dns_servers         => "192.168.220.254",
   dns_search          => "dmz-pod2.lab",
 }

 sysctl::value { "net.ipv4.ip_nonlocal_bind": value => "1" }

 class { keepalived: }
  keepalived::instance { '50':
   interface         => 'eth0',
   virtual_ips       => "${controller_node_address} dev eth0",
   state             => 'MASTER',
   priority          => '101',
 }

 keepalived::instance { '51':
  interface         => 'eth0',
  virtual_ips       => "${$swiftproxy_vip_address} dev eth0",
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

 #Add to galera haproxy config option sever 'mysql-check user haproxy'
 haproxy::config { 'galera':
    order                  	=> '20',
    virtual_ip             	=> $controller_node_address,
    virtual_ip_port        	=> '3306',
    haproxy_config_options 	=> {'mode'    => 'tcp',
				    'option'  => ['tcpka', 'httpchk', 'mysql-check user haproxy'],
				    'balance' => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:3306 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:3306 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:3306 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'keystone_public_internal_cluster':
    order                       => '21',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['5000'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:5000 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:5000 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:5000 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'keystone_admin_cluster':
    order                       => '22',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['35357'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:35357 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:35357 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:35357 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_compute_api1_cluster':
    order                       => '23',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['8773'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8773 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8773 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8773 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_compute_api2_cluster':
    order                       => '24',    
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['8774'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8774 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8774 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8774 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_compute_api3_cluster':
    order                       => '25',        
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['8775'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8775 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8775 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8775 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_volume_cluster':
    order                       => '26',        
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['8776'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8776 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8776 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8776 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'glance_registry_cluster':
    order                       => '27',        
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['9191'],    
    haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:9191 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:9191 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:9191 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'glance_api_cluster':    
    order                       => '28',            
    virtual_ip                  => $controller_node_address,        
    virtual_ip_port             => ['9292'],    
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:9292 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:9292 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:9292 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'swift_proxy_cluster':
    order                       => '29',
    virtual_ip                  => $swiftproxy_vip_address,
    virtual_ip_port             => ['8080'],
    haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${swiftproxy_hostname_primary} ${swiftproxy_ip_primary}:8080 check inter 2000 rise 2 fall 5", "${swiftproxy_hostname_secondary} ${swiftproxy_ip_secondary}:8080 check inter 2000 rise 2 fall 5",],
   }
 }
 
 haproxy::config { 'horizon_cluster':
    order                       => '30',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['80'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:80 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:80 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:80 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'novnc_cluster':
    order                       => '31',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['6080'],
    haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                    'balance'   => 'source',
                                    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:6080 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:6080 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:6080 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'memcached_cluster':
   order                       => '32',
   virtual_ip                  => $controller_node_address,
   virtual_ip_port             => ['11211'],
   haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                   'balance'   => 'source',
                                   'server'  => ["${controller_hostname_primary} ${controller_node_primary}:11211 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:11211 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:11211 check inter 2000 rise 2 fall 5"],
  }
 }

}

node /swiftproxy02/ inherits base {

  # Configure /etc/network/interfaces file
  class { 'networking::interfaces':
  # Node Types: controller, compute, swift-proxy, swift-storage, or load-balancer
   node_type           => load-balancer,
   mgt_is_public       => true,
   mgt_interface       => "eth0",
   mgt_ip              => "192.168.220.62",
   mgt_gateway         => "192.168.220.1",
   dns_servers         => "192.168.220.254",
   dns_search          => "dmz-pod2.lab",
 }

 sysctl::value { "net.ipv4.ip_nonlocal_bind": value => "1" }

 class { keepalived: }
  keepalived::instance { '50':
   interface         => 'eth0',
   virtual_ips       => "${controller_node_address} dev eth0",
   state             => 'BACKUP',
   priority          => '100',
 }

 keepalived::instance { '51':
  interface         => 'eth0',
  virtual_ips       => "${$swiftproxy_vip_address} dev eth0",
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

 #Add to galera haproxy config option sever 'mysql-check user haproxy'
 haproxy::config { 'galera':
    order                  	=> '20',
    virtual_ip             	=> $controller_node_address,
    virtual_ip_port        	=> '3306',
    haproxy_config_options 	=> {'mode'    => 'tcp',
				    'option'  => ['tcpka', 'httpchk', 'mysql-check user haproxy'],
				    'balance' => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:3306 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:3306 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:3306 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'keystone_public_internal_cluster':
    order                       => '21',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['5000'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:5000 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:5000 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:5000 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'keystone_admin_cluster':
    order                       => '22',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['35357'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:35357 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:35357 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:35357 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_compute_api1_cluster':
    order                       => '23',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['8773'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8773 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8773 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8773 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_compute_api2_cluster':
    order                       => '24',    
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['8774'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8774 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8774 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8774 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_compute_api3_cluster':
    order                       => '25',        
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['8775'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8775 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8775 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8775 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'nova_volume_cluster':
    order                       => '26',        
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['8776'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:8776 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:8776 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:8776 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'glance_registry_cluster':
    order                       => '27',        
    virtual_ip                  => $controller_node_address,    
    virtual_ip_port             => ['9191'],    
    haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:9191 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:9191 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:9191 check inter 2000 rise 2 fall 5"],
   }
 }
  
 haproxy::config { 'glance_api_cluster':    
    order                       => '28',            
    virtual_ip                  => $controller_node_address,        
    virtual_ip_port             => ['9292'],    
    haproxy_config_options      => {'option'    => ['tcpka','httpchk','tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:9292 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:9292 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:9292 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'swift_proxy_cluster':
    order                       => '29',
    virtual_ip                  => $swiftproxy_vip_address,
    virtual_ip_port             => ['8080'],
    haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                    'balance'   => 'source',
                                    'server'  => ["${swiftproxy_hostname_primary} ${swiftproxy_ip_primary}:8080 check inter 2000 rise 2 fall 5", "${swiftproxy_hostname_secondary} ${swiftproxy_ip_secondary}:8080 check inter 2000 rise 2 fall 5",],
   }
 }
 
 haproxy::config { 'horizon_cluster':
    order                       => '30',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['80'],
    haproxy_config_options      => {'option'    => ['tcpka', 'httpchk', 'tcplog'],
                                    'balance'   => 'source',
				    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:80 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:80 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:80 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'novnc_cluster':
    order                       => '31',
    virtual_ip                  => $controller_node_address,
    virtual_ip_port             => ['6080'],
    haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                    'balance'   => 'source',
                                    'server'  => ["${controller_hostname_primary} ${controller_node_primary}:6080 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:6080 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:6080 check inter 2000 rise 2 fall 5"],
   }
 }

 haproxy::config { 'memcached_cluster':
   order                       => '32',
   virtual_ip                  => $controller_node_address,
   virtual_ip_port             => ['11211'],
   haproxy_config_options      => {'option'    => ['tcpka', 'tcplog'],
                                   'balance'   => 'source',
                                   'server'  => ["${controller_hostname_primary} ${controller_node_primary}:11211 check inter 2000 rise 2 fall 5", "${controller_hostname_secondary} ${controller_node_secondary}:11211 check inter 2000 rise 2 fall 5","${controller_hostname_tertiary} ${controller_node_tertiary}:11211 check inter 2000 rise 2 fall 5"],
  }
 }

}

