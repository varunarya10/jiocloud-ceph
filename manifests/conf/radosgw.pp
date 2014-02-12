# Define a radosgw
#
define ceph::conf::radosgw (
  $keystone_url,
  $keystone_admin_token,
  $keystone_accepted_roles = 'Member, admin, swiftoperator',
  $keystone_token_cache_size = 500,
  $keystone_revocation_interval = 600,
  $nss_db_path = '/var/lib/ceph/nss',
  $keyring = '/etc/ceph/keyring',
  $socket = '/var/run/ceph/radosgw.sock',
  $logfile = '/var/log/ceph/radosgw.log',
  $region            = 'RegionOne',
  $public_protocol   = 'http',
  $public_address    = '127.0.0.1',
  $public_port       = undef,
  $admin_protocol    = 'http',
  $admin_address     = undef,
  $internal_protocol = 'http',
  $internal_address  = undef,
  $auth_name	= 'swift',
) {

  if ! $public_port {
    $real_public_port = $port
  } else {
    $real_public_port = $public_port
  }
  if ! $admin_address {
    $real_admin_address = $public_address
  } else {
    $real_admin_address = $admin_address
  }
  if ! $internal_address {
    $real_internal_address = $public_address
  } else {
    $real_internal_address = $internal_address
  }

  concat::fragment { "ceph-radosgw-${name}.conf":
    target  => '/etc/ceph/ceph.conf',
    order   => '70',
    content => template('ceph/ceph.conf-radosgw.erb'),
  }


  keystone_service { $auth_name:
    ensure      => present,
    type        => 'object-store',
    description => 'Openstack Object-Store Service',
  }
  
  keystone_endpoint { "${region}/${auth_name}":
    ensure       => present,
    public_url   => "${public_protocol}://${public_address}:${real_public_port}/v1/AUTH_%(tenant_id)s",
    admin_url    => "${admin_protocol}://${real_admin_address}:${port}/",
    internal_url => "${internal_protocol}://${real_internal_address}:${port}/v1/AUTH_%(tenant_id)s",
  }

  if $keystone_accepted_roles {
    #Roles like "admin" may be defined elsewhere, so use ensure_resource
    ensure_resource('keystone_role', $keystone_accepted_roles, { 'ensure' => 'present' })
  }
}
