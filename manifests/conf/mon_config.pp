# Define a mon
#
define ceph::conf::mon_config (
  $mon_addr,
  $mon_port = 6789,
) {

  concat::fragment { "ceph-mon-${name}.conf":
    target  => '/etc/ceph/ceph.conf',
    order   => '50',
    content => template('ceph/ceph.conf-mon_config.erb'),
  }


}
