# Install and configure ceph radosgw
#
# == Parameters
# [*package_ensure*] The ensure state for the ceph package.
#   Optional. Defaults to present.
#
# == Dependencies
#
# none
#
# == Authors
#
#  Harish Kumar	harish.m.kumar@ril.com
#
#
#
class ceph::radosgw (
  $package_ensure = 'present',
  $configure_apache        = true,
  $bind_address            = '0.0.0.0',
  
  $serveradmin_email    = 'root@localhost',
  $fastcgi_ext_script   = '/var/www/s3gw.fcgi',
  $socket   = '/var/run/ceph/radosgw.sock',
  $fastcgi_ext_script_source = undef,

  $listen_ssl   = false,
  $radosgw_cert_file_source     = undef,
  $radosgw_cert_file = undef,
  $radosgw_key_file  = undef,
  $radosgw_key_file_source  = undef,
  $radosgw_ca_file   = undef,
  $radosgw_ca_file_source   = undef,
  $logfile		= '/var/log/ceph/radosgw',
  $keyring	= '/etc/ceph/keyring',  
 
) {

  include 'ceph::conf'

  ceph::conf::radosgw { $name:
    keyring  	=> $keyring,
    socket 	=> $socket,
    logfile	=> $logfile,
  }

  package { 'radosgw':
    ensure => $package_ensure
  }

  if $configure_apache {
    class { 'ceph::radosgw::apache':
      bind_address => $bind_address,
      listen_ssl   => $listen_ssl,
      radosgw_cert_file => $radosgw_cert_file,
      radosgw_key_file  => $radosgw_key_file,
      radosgw_ca_file   => $radosgw_ca_file,
      radosgw_cert_file_source => $radosgw_cert_file_source,
      radosgw_key_file_source  => $radosgw_key_file_source,
      radosgw_ca_file_source   => $radosgw_ca_file_source,
      serveradmin_email 	=> $serveradmin_email,
      fastcgi_ext_script	=> $fastcgi_ext_script,
      fastcgi_ext_socket	=> $fastcgi_ext_socket,
      fastcgi_ext_script_source	=> $fastcgi_ext_script_source,
    }
  }

exec { 'ceph-radosgw-key':
    command => "ceph-authtool $keyring \
--name=client.radosgw.gateway \
--add-key \
$(ceph --name client.admin --keyring $keyring \
  auth get-or-create-key client.radosgw.gateway \
    mon 'allow r' \
    osd 'allow rwx' )",
#    creates => '/etc/ceph/keyring',
    require => Package['radosgw'],
    unless  => "ceph auth list | egrep 'client.radosgw.gateway'",
  }



}
