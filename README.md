I have a functional OpenStack HA cluster.  I still need to perform additional testing, rebuilds, and create documentation.  The example is based on 3 Controller Nodes, 2 Compute Nodes, 1 Swift Proxy Node, 3 Swift Storage Nodes, and 2 HAproxy Nodes.

For the time being, you can use my puppet modules:

    https://github.com/danehans

Step 1: Use the Build Node Guide to create your Build Node.  

Step 2: Backup the standard puppet modules that are included in the Cisco OpenStack Packages:

    mv /usr/share/puppet/modules/openstack /usr/share/puppet/modules/openstack.orig
    
    mv /usr/share/puppet/modules/nova /usr/share/puppet/modules/nova.orig
  
    mv /usr/share/puppet/modules/keystone /usr/share/puppet/modules/keystone.orig
  
    mv /usr/share/puppet/modules/glance /usr/share/puppet/modules/glance.orig
  
    mv /usr/share/puppet/modules/horizon /usr/share/puppet/modules/horizon.orig

    mv /usr/share/puppet/modules/mysql /usr/share/puppet/modules/mysql.orig

Step 3: Pull Updated Puppet HA Modules from my Github Repo's:

    cd /usr/share/puppet/module
  
    git clone https://github.com/danehans/puppet-openstack.git openstack
  
    git clone https://github.com/danehans/puppetlabs-glance.git glance
  
    git clone https://github.com/danehans/puppetlabs-keystone.git keystone
  
    git clone https://github.com/danehans/puppet-galera.git galera
  
    git clone https://github.com/danehans/puppet-module-keepalived.git keepalived
  
    git clone https://github.com/danehans/puppet-haproxy.git haproxy
  
    git clone https://github.com/danehans/puppetlabs-horizon.git horizon
  
    git clone https://github.com/danehans/puppetlabs-mysql.git mysql

    git clone https://github.com/danehans/puppetlabs-nova.git nova

Step 4: For the Nova module, change to the rmq-ha branch

    cd nova

Then go:

    git checkout -t -b rmq-ha remotes/origin/rmq-ha
 
Step 5: Now that you have pulled all the Puppet HA modules, copy the following .pp files:
 
    cp /usr/share/puppet/modules/openstack/examples/ha-site.pp /etc/puppet/manifests/site.pp    
    cp /usr/share/puppet/modules/openstack/examples/haproxy-nodes.pp /etc/puppet/manifests/haproxy-nodes.pp
    cp /usr/share/puppet/modules/openstack/examples/cobbler-node.pp /etc/puppet/manifests/cobbler-node.pp
    cp /usr/share/puppet/modules/openstack/examples/swift-nodes.pp /etc/puppet/manifests/swift-nodes.pp

Step 6: Edit the .pp files accordingly.  I still need to document things, but you should be familiar with this process.

Step 7: Deploy your nodes in the following order:

  A. HAproxy Nodes
  Note: Make sure the haproxy/keepalived services are running and the config files look good before proceeding.
 
  B. Swift Storage Nodes
  Note: The drives should be zero'ed out if you are rebuilding the swift storage nodes.  Use clean-disk.pp from Cisco repo.
 
  C. Swift Proxy Nodes
 
  D. Controller 1
  
  E. Compute Nodes
  
  F. Test to make sure environment is functional before introducing additional Controller Nodes.
  
  G. Controller Node 2 and 3
 
Step 7: Have a beer... you deserve it! 
 
