# Define a osd
#
define ceph::conf::osd (
  $device,
  $cluster_addr = undef,
  $public_addr  = undef,
) {

  concat::fragment { "ceph-osd-${name}.conf":
    target  => '/etc/ceph/ceph.conf',
    order   => '80',
    content => template('ceph/ceph.conf-osd.erb'),
  }

}
