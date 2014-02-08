# Define a osd
#
define ceph::conf::osd (
  $device,
  $journal_device = undef,
  $journal_type = 'filesystem',
  $cluster_addr = undef,
  $public_addr  = undef,
) {

  file {"/tmp/ceph_osd${name}": content => "$device,$journal_device,$journal_type\n"}

  concat::fragment { "ceph-osd-${name}.conf":
    target  => '/etc/ceph/ceph.conf',
    order   => '80',
    content => template('ceph/ceph.conf-osd.erb'),
  }

}
