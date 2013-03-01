#
# == Class: openstack::glance
#
# Installs and configures Glance
# Assumes the following:
#   - Keystone for authentication
#   - keystone tenant: services
#   - keystone username: glance
#   - storage backend: file
#
# === Parameters
#
# [db_host] Host where DB resides. Required.
# [glance_user_password] Password for glance auth user. Required.
# [glance_db_password] Password for glance DB. Required.
# [registry_host] Address for Glance API to use for contacting the registry service.  Defaults to '0.0.0.0'
# [bind_address] Address to bind Glance API and Registry services to.  Defaults to '0.0.0.0'
# [keystone_host] Host whre keystone is running. Optional. Defaults to '127.0.0.1'
# [db_type] Type of sql databse to use. Optional. Defaults to 'mysql'
# [glance_db_user] Name of glance DB user. Optional. Defaults to 'glance'
# [glance_db_dbname] Name of glance DB. Optional. Defaults to 'glance'
# [glance_on_swift] Optional. Use Swift as a backend for storing Glance images.  Defaults to false
# [swift_store_user] Optional. User to authenticate against the Swift authentication service.  Defaults to admin:admin
# [swift_store_key] Optional. Auth key for the user authenticating against the Swift authentication service. Defaults to keystone_admin
# [swift_store_auth_address] Optional. Address where the Swift authentication service lives. Defaults to "http://${keystone_host}:5000/v2.0/" 
# [verbose] Log verbosely. Optional. Defaults to 'False'
# [enabled] Used to indicate if the service should be active (true) or passive (false).
#   Optional. Defaults to true
#
# === Example
#
# class { 'openstack::glance':
#   glance_user_password => 'changeme',
#   db_password          => 'changeme',
#   db_host              => '127.0.0.1',
# }

class openstack::glance (
  $db_host,
  $glance_user_password,
  $glance_db_password,
  $registry_host            = '0.0.0.0',
  $bind_address             = '0.0.0.0',
  $keystone_host            = '127.0.0.1',
  $db_type                  = 'mysql',
  $glance_db_user           = 'glance',
  $glance_db_dbname         = 'glance',
  $verbose                  = 'False',
  $glance_on_swift          = false,
  $swift_store_user	    = undef,
  $swift_store_key          = undef,
  $swift_store_auth_address = "http://${keystone_host}:5000/v2.0/",
  $enabled                  = true
) {

  # Configure the db string
  case $db_type {
    'mysql': {
      $sql_connection = "mysql://${glance_db_user}:${glance_db_password}@${db_host}/${glance_db_dbname}"
    }
  }

  # Install and configure glance-api
  class { 'glance::api':
    verbose           => $verbose,
    debug             => $verbose,
    auth_type         => 'keystone',
    auth_port         => '35357',
    auth_host         => $keystone_host,
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    registry_host     => $registry_host,
    bind_host         => $bind_address,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
  }

  # Install and configure glance-registry
  class { 'glance::registry':
    verbose           => $verbose,
    debug             => $verbose,
    auth_host         => $keystone_host,
    auth_port         => '35357',
    auth_type         => 'keystone',
    keystone_tenant   => 'services',
    keystone_user     => 'glance',
    keystone_password => $glance_user_password,
    bind_host         => $bind_address,
    sql_connection    => $sql_connection,
    enabled           => $enabled,
  }

  # Configure file storage backend
  if $glance_on_swift {
    class { 'glance::backend::swift':
      swift_store_user                    => $swift_store_user,
      swift_store_key                     => $swift_store_key,
      swift_store_auth_address            => $swift_store_auth_address,
      swift_store_create_container_on_put => 'true'
    }
  } else {
    class { 'glance::backend::file': }
  }
}
