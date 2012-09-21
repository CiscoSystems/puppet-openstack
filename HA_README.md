Validate Cobbler Preseed

Validate cobbler-node.pp settings

Validate the RAID config

Backup Standard Puppet Modules:

  mv /usr/share/puppet/modules/openstack /usr/share/puppet/modules/openstack.orig
  
  mv /usr/share/puppet/modules/nova /usr/share/puppet/modules/nova.orig

  mv /usr/share/puppet/modules/keystone /usr/share/puppet/modules/keystone.orig

  mv /usr/share/puppet/modules/glance /usr/share/puppet/modules/glance.orig

  mv /usr/share/puppet/modules/horizon /usr/share/puppet/modules/horizon.orig

Pull Updated HA Modules from my Github Repo's:

  cd /usr/share/puppet/module

  git clone https://github.com/danehans/puppet-openstack.git openstack

  git clone https://github.com/danehans/puppetlabs-glance.git glance

  git clone https://github.com/danehans/puppetlabs-keystone.git keystone

  git clone https://github.com/danehans/puppet-galera.git galera

  git clone https://github.com/danehans/puppet-module-keepalived.git keepalived

  git clone https://github.com/danehans/puppet-haproxy.git haproxy

  git clone https://github.com/danehans/puppetlabs-horizon.git horizon

  git clone https://github.com/danehans/puppetlabs-nova.git nova

For the Nova module, change to the rmq-ha branch

  cd nova

Then go:

  git branch -a

...to see what branches you have. One of the lines you see might be: remotes/origin/[NameOfYourBranch]

 git checkout -t -b [NameOfYourBranch] remotes/origin/[NameOfYourBranch]
