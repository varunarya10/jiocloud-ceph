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
) {


  concat::fragment { "ceph-radosgw-${name}.conf":
    target  => '/etc/ceph/ceph.conf',
    order   => '70',
    content => template('ceph/ceph.conf-radosgw.erb'),
    notify => Service['radosgw'],
  }


}
