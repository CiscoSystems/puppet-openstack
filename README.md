I have a functional OpenStack HA cluster.  I still need to perform additional testing, rebuilds, and create documentation.  The example is based on 3 Controller Nodes, 2 Compute Nodes, 2 Swift Proxy Nodes, 3 Swift Storage Nodes, and 2 HAproxy Nodes.

For the time being, you can use my puppet modules:

    https://github.com/danehans

Step 1: Use the Cisco Build Node Deployment Guide to create your Build Node (Cobbler, Puppetmaster, etc.).  

Step 2: Backup the standard puppet modules that are included in the Cisco OpenStack packages:

    mv /usr/share/puppet/modules/openstack /usr/share/puppet/modules/openstack.orig
    
    mv /usr/share/puppet/modules/nova /usr/share/puppet/modules/nova.orig
  
    mv /usr/share/puppet/modules/keystone /usr/share/puppet/modules/keystone.orig
  
    mv /usr/share/puppet/modules/glance /usr/share/puppet/modules/glance.orig
  
    mv /usr/share/puppet/modules/horizon /usr/share/puppet/modules/horizon.orig

    mv /usr/share/puppet/modules/cobbler /usr/share/puppet/modules/cobbler.orig
    
    mv /usr/share/puppet/modules/rabbitmq /usr/share/puppet/modules/rabbitmq.orig

Step 3: Pull the updated Puppet HA modules from my Github Repo's:

    cd /usr/share/puppet/modules
  
    git clone https://github.com/danehans/puppet-openstack.git openstack
  
    git clone https://github.com/danehans/puppetlabs-glance.git glance
  
    git clone https://github.com/danehans/puppetlabs-keystone.git keystone
  
    git clone https://github.com/danehans/puppet-galera.git galera
  
    git clone https://github.com/danehans/puppet-module-keepalived.git keepalived
  
    git clone https://github.com/danehans/puppet-haproxy.git haproxy
  
    git clone https://github.com/danehans/puppetlabs-horizon.git horizon
  
    git clone https://github.com/danehans/puppetlabs-networking.git networking

    git clone https://github.com/danehans/puppet-cobbler.git cobbler

    git clone git://github.com/danehans/puppetlabs-rabbitmq.git rabbitmq

    git clone https://github.com/danehans/puppetlabs-nova.git nova

Step 4: For the Nova module, change to the rmq-ha branch

    cd nova

Then go:

    git checkout -t -b rmq-ha remotes/origin/rmq-ha

Step 5: For the RabbitMQ module, change to the cluster-support branch

    cd rabbitmq

Then go:

    git checkout -t -b rmq-ha remotes/origin/cluster-support

Step 6: Now that you have pulled all the Puppet HA modules, copy the following .pp files:
 
    cp /usr/share/puppet/modules/openstack/examples/ha-site.pp /etc/puppet/manifests/site.pp    
    cp /usr/share/puppet/modules/openstack/examples/haproxy-nodes.pp /etc/puppet/manifests/haproxy-nodes.pp
    cp /usr/share/puppet/modules/openstack/examples/cobbler-node.pp /etc/puppet/manifests/cobbler-node.pp
    cp /usr/share/puppet/modules/openstack/examples/swift-nodes.pp /etc/puppet/manifests/swift-nodes.pp

Step 7: Edit the .pp files accordingly.  I still need to document this step in more detail, but you should be familiar with this process.

Step 8: Deploy your nodes in the following order.  For the time being, you need to perform multiple puppet runs for most nodes to deploy properly.

  A. HAproxy Nodes
  Note: Make sure the haproxy/keepalived services are running and the config files look good before proceeding.  It is also very important that you test connectivity to Virtual IP addresses (telnet <vip> <port>).  If the VIP's are not working then the build-out of nodes will fail.
 
  B. Swift Storage Nodes
  Note: The drives should be zero'ed out if you are rebuilding the swift storage nodes.  Use clean-disk.pp from Cisco repo.
 
  C. Swift Proxy Node 1
  Note: Make sure the ring is functional before adding the 2nd Proxy.

  D.  Swift Proxy Node 2
  Note: Make sure the ring is functional before proceeding.
 
  D. Controller Nodes 1-3
  Note: You must ensure that the HAproxy Virtual IP address for the Controller cluster is working or your puppet run will fail.
  
  E. Compute Nodes
  
  F. Test to make sure environment is functional.
 
Step 9: Email danehans@cisco.com if you have any problems.
 
