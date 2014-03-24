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
  $radosgw_keyring = '/etc/ceph/keyring.radosgw.gateway',
  $region            = 'RegionOne',
  $public_protocol   = 'http',
  $public_address    = '127.0.0.1',
  $public_port       = undef,
  $admin_protocol    = 'http',
  $admin_address     = undef,
  $internal_protocol = 'http',
  $internal_address  = undef,
  radosgw_apache_version = '2.2.22-2precise.ceph',
  radosgw_apache_deps = undef,
) {

  Exec['ceph-radosgw-key'] ~> Service['radosgw']

  #include 'ceph::conf'

  ceph::conf::radosgw { $name:
    keyring  	=> $radosgw_keyring,
    socket 	=> $socket,
    logfile	=> $logfile,
    keystone_url => $keystone_url,
    keystone_admin_token => $keystone_admin_token,
    keystone_accepted_roles => $keystone_accepted_roles,
    keystone_token_cache_size => $keystone_token_cache_size,
    keystone_revocation_interval => $keystone_revocation_interval,
    nss_db_path => $nss_db_path,
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
      fastcgi_ext_socket	=> $socket,
      fastcgi_ext_script_source	=> $fastcgi_ext_script_source,
      radosgw_apache_version	=> $radosgw_apache_version,
      radosgw_apache_deps	=> $radosgw_apache_deps
    }
  }

exec { 'ceph-radosgw-key':
    command => "ceph-authtool --create-keyring $radosgw_keyring; ceph-authtool $radosgw_keyring \
--name=client.radosgw.gateway \
--add-key \
$(ceph --name client.admin --keyring $keyring \
  auth get-or-create-key client.radosgw.gateway \
    mon 'allow rw' \
    osd 'allow rwx' ); chmod a+r $radosgw_keyring",
    require => Package['radosgw'],
    unless  => "egrep 'client.radosgw.gateway' $radosgw_keyring",
  }

  service { 'radosgw':
	ensure     => 'running',
	enable	   => true,
	hasstatus => true,
	hasrestart => true,
  }

}
