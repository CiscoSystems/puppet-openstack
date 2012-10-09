# This example requires the following modules: 
# 1. https://github.com/danehans/puppet-cobbler
# 2. https://github.com/danehans/puppet-networking
# 
# == Example
#
# add this to your site.pp file:
# import "cobbler-node"
# in your site.pp file, add a node definition like:
# node 'cobbler.example.com' inherits cobbler-node { }
#

# A node definition for cobbler
# You will likely also want to change the IP addresses, domain name, and perhaps
# even the proxy address
# If you are not using UCS blades, don't worry about the org-EXAMPLE, and if you are
# and aren't using an organization domain, just leave the value as ""
# An example MD5 crypted password is ubuntu: $6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1
# which is used by the cobbler preseed file to set up the default admin user.

###### GLOBAL VARIABLES #########
$cobbler_node_ip = "192.168.220.254"
$node_public_interface = "eth1"
$node_public_netmask = "255.255.255.0"
#################################

node /cobbler-node/ {

 class { cobbler:
  node_subnet => '192.168.220.0',
  node_netmask => '255.255.255.0',
  node_gateway => '192.168.220.1',
  node_dns => "${cobbler_node_ip}",
  ip => "${cobbler_node_ip}",
  dns_service => 'dnsmasq',
  dhcp_service => 'dnsmasq',
  dhcp_ip_low => '192.168.220.240',
  dhcp_ip_high => '192.168.220.250',
  domain_name => 'dmz-pod2.lab',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$UfgWxrIv$k4KfzAEMqMg.fppmSOTd0usI4j6gfjs0962.JXsoJRWa5wMz8yQk4SfInn4.WZ3L/MCt5u.62tHDGB36EhiKF1',
 }

# This will load the Ubuntu precise x86_64 server iso into cobbler
 cobbler::ubuntu { "precise":
 }

# This will build a preseed file called 'cisco-preseed' in /etc/cobbler/preseeds/
 cobbler::ubuntu::preseed { "cisco-preseed":
  packages => "gfs2-utils openssh-server vim vlan lvm2 ntp puppet ipmitool",
  ntp_server => "192.168.220.1",
  late_command => '
sed -e "/logdir/ a pluginsync=true" -i /target/etc/puppet/puppet.conf ; \
sed -e "/logdir/ a server=build-os.dmz-pod2.lab" -i /target/etc/puppet/puppet.conf ; \
sed -e "s/START=no/START=yes/" -i /target/etc/default/puppet ; \
echo -e "server 192.168.220.1 iburst" > /target/etc/ntp.conf ; \
echo "8021q" >> /target/etc/modules ; \
echo -e "# Private Interface\nauto eth0.221\niface eth0.221 inet manual\n\tvlan-raw-device eth0\n\tup ifconfig eth0.221 0.0.0.0 up\n" >> /target/etc/network/interfaces ; \
true
',
  proxy => "http://${cobbler_node_ip}:3142/",
  password_crypted => '$6$5NP1.NbW$WOXi0W1eXf9GOc0uThT5pBNZHqDH9JNczVjt9nzFsH7IkJdkUpLeuvBU.Zs9x3P6LBGKQh6b0zuR8XSlmcuGn.',
  expert_disk => true,
  diskpart => ['/dev/sdc'],
  boot_disk => '/dev/sdc',
 }

# The following are node definitions that will allow cobbler to PXE boot the hypervisor OS onto the system (based on the preseed built above)
# You will want to adjust the "title" (maps to system name in cobbler), mac address (this is the PXEboot MAC target), IP (this is a static DHCP delivered address for this particular node), domain (added to /etc/resolv.conf for proper function), power address, the same one for power-strip based power control, per-node for IPMI/CIMC/ILO based control, power-ID needs to map to power port or service profile name (in UCSM based deployements)

cobbler::node { "control01":
 mac => "A4:4C:11:13:8B:D2",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.2",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "control02":
 mac => "A4:4C:11:13:8B:1A",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.3",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "control03":
 mac => "A4:4C:11:13:5E:5C",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.13",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "compute01":
 mac => "A4:4C:11:13:52:80",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.4",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "compute02":
 mac => "A4:4C:11:13:A7:F1",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.5",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "compute03":
 mac => "A4:4C:11:13:43:DB",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.6",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

cobbler::node { "swiftproxy01":
 mac => "A4:4C:11:13:3D:07",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.7",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }
cobbler::node { "swiftproxy02":
 mac => "A4:4C:11:13:44:93",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.8",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }
cobbler::node { "swift01":
 mac => "A4:4C:11:13:BA:17",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.10",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }
cobbler::node { "swift02":
 mac => "A4:4C:11:13:BC:56",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.11",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }
cobbler::node { "swift03":
 mac => "A4:4C:11:13:B9:8D",
 profile => "precise-x86_64-auto",
 domain => "dmz-pod2.lab",
 preseed => "/etc/cobbler/preseeds/cisco-preseed",
 power_address => "192.168.220.12",
 power_type => "ipmitool",
 power_user => "admin",
 power_password => "password",
 }

# Repeat as necessary.
}

