# == Class: ceph::radosgw::apache
#
# Configures Apache for radosgw.
#
# === Parameters
#
#  [*bind_address*]
#    (optional) Bind address in Apache for Radosgw. (Defaults to '0.0.0.0')
#
#  [*listen_ssl*]
#    (optional) Enable SSL support in Apache. (Defaults to false)
#
#  [*radosgw_cert*]
#    (required with listen_ssl) Certificate to use for SSL support.
#
#  [*radosgw_key*]
#    (required with listen_ssl) Private key to use for SSL support.
#
#  [*radosgw_ca*]
#    (required with listen_ssl) CA certificate to use for SSL support.
#
class ceph::radosgw::apache (
  $bind_address = '0.0.0.0',
  $fqdn		= 'localhost',
  $serveradmin_email	= 'root@localhost',
  $fastcgi_ext_script	= '/var/www/s3gw.fcgi',
  $fastcgi_ext_socket	= '/var/run/ceph/radosgw.sock',
  $fastcgi_ext_script_source = undef,
  
  $listen_ssl   = false,
  $radosgw_cert_file_source	= undef,
  $radosgw_cert_file = undef,
  $radosgw_key_file  = undef,
  $radosgw_key_file_source  = undef,
  $radosgw_ca_file   = undef,
  $radosgw_ca_file_source   = undef,
) {

  include ceph::radosgw::params
  include ::apache
  include ::apache::mod::fastcgi


  Package['radosgw'] -> Package[$::ceph::radosgw::params::http_service]
#  File[$::ceph::radosgw::params::httpd_config_file] ~> Service[$::ceph::radosgw::params::http_service]

 # file { $log_dir:
 #   ensure  => directory,
 #   owner   => $::ceph::radosgw::params::apache_user,
 #   group   => $::ceph::radosgw::params::apache_group,
 #   before  => Service[$::ceph::radosgw::params::http_service],
 #   mode    => '0751',
 #   require => Package['radosgw']
 # }

##FIXME: NEED TO CHECK THE FILE existance,
  if  $radosgw_cert_file_source != undef {
    file { $radosgw_cert_file:
	ensure        => file,
	owner         => $::ceph::radosgw::params::apache_user,
  	group         => $::ceph::radosgw::params::apache_group,
  	mode          => 640,
  	source        => $radosgw_cert_file_source,
	before  => File[$::ceph::radosgw::params::httpd_config_file],
    }
  }

  if  $fastcgi_ext_script_source != undef {
    file { $fastcgi_ext_script:
        ensure        => file,
        owner         => $::ceph::radosgw::params::apache_user,
        group         => $::ceph::radosgw::params::apache_group,
        mode          => 640,
        source        => $fastcgi_ext_script_source,
        before  => File[$::ceph::radosgw::params::httpd_config_file],
    }
  }

  if  $radosgw_key_file_source != undef {
    file { $radosgw_key_file:
        ensure        => file,
        owner         => $::ceph::radosgw::params::apache_user,
        group         => $::ceph::radosgw::params::apache_group,
        mode          => 640,
        source        => $radosgw_key_file_source,
	before  => File[$::ceph::radosgw::params::httpd_config_file],
    }
  }

  if  $radosgw_ca_file_source != undef {
    file { $radosgw_ca_file:
        ensure        	=> file,
        owner         	=> $::ceph::radosgw::params::apache_user,
        group         	=> $::ceph::radosgw::params::apache_group,
        mode          	=> 640,
        source         	=> $radosgw_ca_file_source,
	before  	=> File[$::ceph::radosgw::params::httpd_config_file],
    }
  }

  file { $::ceph::radosgw::params::httpd_config_file:
    ensure  => file,
    owner   => $::ceph::radosgw::params::apache_user,
    group   => $::ceph::radosgw::params::apache_group,
    content => template('ceph/radosgw-apache.conf.erb'),
    before  => Service[$::ceph::radosgw::params::http_service],
    mode    => '0644',
    require => Package['radosgw']
  }

  if $listen_ssl {
    include apache::mod::ssl

    if $radosgw_ca == undef {
      fail('The radosgw_ca parameter is required when listen_ssl is true')
    }

    if $radosgw_cert == undef {
      fail('The radosgw_cert parameter is required when listen_ssl is true')
    }

    if $radosgw_key == undef {
      fail('The radosgw_key parameter is required when listen_ssl is true')
    }

  }

}