# Configure a ceph osd device
#
# == Namevar
# the resource name is the full path to the device to be used.
#
# == Dependencies
#
# none
#
# == Authors
#
#  François Charlier francois.charlier@enovance.com
#
# == Copyright
#
# Copyright 2013 eNovance <licensing@enovance.com>
#

define ceph::osd::device (
	$osd_journal_type	= 'filesystem',
	$osd_journal_size 	= 1
) {

  include ceph::osd
  include ceph::conf
  include ceph::params

  $devname = regsubst($name, '.*/', '')

  exec { "mktable_gpt_${devname}":
    command => "parted -a optimal --script ${name} mktable gpt",
    unless  => "parted --script ${name} print|grep -sq 'Partition Table: gpt'",
    require => Package['parted']
  }

  if $osd_journal_type == 'first_partition' {
    exec { "mkpart_journal_${devname}":
         command => "parted -a optimal -s ${name} mkpart ceph_journal 0GiB ${osd_journal_size}GiB",
         unless  => "parted ${name} print | egrep '^ 1.*ceph_journal$'",
         require => [Package['parted'], Exec["mktable_gpt_${devname}"]]
    }
    exec { "mkpart_${devname}":
    	command => "parted -a optimal -s ${name} mkpart ceph ${osd_journal_size}GiB 100%",
    	unless  => "parted ${name} print | egrep '^ 2.*ceph$'",
    	require => [Package['parted'], Exec["mktable_gpt_${devname}"], Exec["mkpart_journal_${devname}"]]
    }
    exec { "mkfs_${devname}":
    	command => "mkfs.xfs -f -d agcount=${::processorcount} -l \
size=1024m -n size=64k ${name}2",
    	unless  => "xfs_admin -l ${name}2",
    	require => [Package['xfsprogs'], Exec["mkpart_${devname}"]],
    }
    
    $blkid_uuid_fact = "blkid_uuid_${devname}2"
    $osd_id_fact = "ceph_osd_id_${devname}2"
    $osd_data_device_name = "${name}2"
    $osd_journal_device_name = "${name}1"
  } elsif $osd_journal_type == 'filesystem' {

    exec { "mkpart_${devname}":
    	command => "parted -a optimal -s ${name} mkpart ceph 0% 100%",
    	unless  => "parted ${name} print | egrep '^ 1.*ceph$'",
    	require => [Package['parted'], Exec["mktable_gpt_${devname}"]]
    }

    exec { "mkfs_${devname}":
      command => "mkfs.xfs -f -d agcount=${::processorcount} -l \
size=1024m -n size=64k ${name}1",
      unless  => "xfs_admin -l ${name}1",
      require => [Package['xfsprogs'], Exec["mkpart_${devname}"]],
    }

    $blkid_uuid_fact = "blkid_uuid_${devname}1"
    $osd_id_fact = "ceph_osd_id_${devname}1"
    $osd_data_device_name = "${name}1"
  }
  notify { "BLKID FACT ${osd_data_device_name}: ${blkid_uuid_fact}": }
  $blkid = inline_template('<%= scope.lookupvar(blkid_uuid_fact) or "undefined" %>')
  notify { "BLKID ${devname}: ${blkid}": }

  if $blkid != 'undefined'  and defined( Ceph::Key['admin'] ){
    exec { "ceph_osd_create_${devname}":
      command => "ceph osd create ${blkid}",
      unless  => "ceph osd dump | grep -sq ${blkid}",
      require => Ceph::Key['admin'],
    }

    notify { "OSD ID FACT ${devname}: ${osd_id_fact}": }
    $osd_id = inline_template('<%= scope.lookupvar(osd_id_fact) or "undefined" %>')
    notify { "OSD ID ${devname}: ${osd_id}":}

    if $osd_id != 'undefined' {

      ceph::conf::osd { $osd_id:
        device       => $osd_data_device_name,
	journal_type	=> $osd_journal_type,
	journal_device	=> $osd_journal_device_name,
        cluster_addr => $::ceph::osd::cluster_address,
        public_addr  => $::ceph::osd::public_address,
      }

      $osd_data = regsubst($::ceph::conf::osd_data, '\$id', $osd_id)

      file { $osd_data:
        ensure => directory,
      }

#      file { "${osd_data}/journal":
#        ensure  => link,
#        target  => "/dev/mapper/rootfs-journal--${devname}1",
#        owner   => 'root',
#        group   => 'root',
#        mode    => '0660',
#        require => Mount[$osd_data],
#        before  => Service["ceph-osd.${osd_id}"];
#      }

      mount { $osd_data:
        ensure  => mounted,
        device  => "$osd_data_device_name",
        atboot  => true,
        fstype  => 'xfs',
        options => 'rw,noatime,inode64',
        pass    => 2,
        require => [
          Exec["mkfs_${devname}"],
          File[$osd_data]
        ],
      }

      exec { "ceph-osd-mkfs-${osd_id}":
        command => "ceph-osd -c /etc/ceph/ceph.conf \
-i ${osd_id} \
--mkfs \
--mkkey \
--osd-uuid ${blkid}
",
        creates => "${osd_data}/keyring",
        unless  => "ceph auth list | egrep '^osd.${osd_id}$'",
        require => [
          Mount[$osd_data],
          Concat['/etc/ceph/ceph.conf'],
          ],
      }

      exec { "ceph-osd-register-${osd_id}":
        command => "\
ceph auth add osd.${osd_id} osd 'allow *' mon 'allow rwx' \
-i ${osd_data}/keyring",
        unless  => "ceph auth list | egrep '^osd.${osd_id}$'",
        require => Exec["ceph-osd-mkfs-${osd_id}"],
      }

      service { "ceph-osd.${osd_id}":
        ensure    => running,
        provider  => $::ceph::params::service_provider,
        start     => "service ceph start osd.${osd_id}",
        stop      => "service ceph stop osd.${osd_id}",
        status    => "service ceph status osd.${osd_id}",
        subscribe => Concat['/etc/ceph/ceph.conf'],
      }

    }

  }

}
