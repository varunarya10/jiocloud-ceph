# Define a mds
#
define ceph::conf::clients (
  $keyring = "/etc/ceph/keyring.$name",
) {

  concat::fragment { "ceph-clients-${name}.conf":
    target  => '/etc/ceph/ceph.conf',
    order   => '60',
    content => template('ceph/ceph.conf-clients.erb'),
  }

}
