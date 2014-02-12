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
  $keystone_url,
  $keystone_admin_token,
  $keystone_accepted_roles = 'Member, admin, swiftoperator',
  $keystone_token_cache_size = 500,
  $keystone_revocation_interval = 600,
  $nss_db_path = '/var/lib/ceph/nss',
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

  $region            = 'RegionOne',
  $public_protocol   = 'http',
  $public_address    = '127.0.0.1',
  $public_port       = undef,
  $admin_protocol    = 'http',
  $admin_address     = undef,
  $internal_protocol = 'http',
  $internal_address  = undef
 
) {

  include 'ceph::conf'

  ceph::conf::radosgw { $name:
    keyring  	=> $keyring,
    socket 	=> $socket,
    logfile	=> $logfile,
    keystone_url => $keystone_url,
    keystone_admin_token => $keystone_admin_token,
    keystone_accepted_roles => $keystone_accepted_roles,
    keystone_token_cache_size => $keystone_token_cache_size,
    keystone_revocation_interval => $keystone_revocation_interval,
    nss_db_path => $nss_db_path,
    region            =>  $region,
    public_protocol   = $public_protocol,
    public_address    = $public_address,
    public_port       = $public_port,
    admin_protocol    = $admin_protocol,
    admin_address     = $admin_address,
    internal_protocol = $internal_protocol,
    internal_address  = $internal_address
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
    unless  => "egrep 'client.radosgw.gateway' $keyring",
  }



}
