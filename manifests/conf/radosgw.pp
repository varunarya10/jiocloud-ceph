# Define a radosgw
#
define ceph::conf::radosgw (
  $keyring = '/etc/ceph/keyring',
  $socket = '/var/run/ceph/radosgw.sock',
  $logfile = '/var/log/ceph/radosgw.log',
) {

  concat::fragment { "ceph-radosgw-${name}.conf":
    target  => '/etc/ceph/ceph.conf',
    order   => '70',
    content => template('ceph/ceph.conf-radosgw.erb'),
  }

}
