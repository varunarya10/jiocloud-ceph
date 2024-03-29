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
  $radosgw_apache_version = '2.2',
) {

  include ceph::radosgw::params
  apt::pin { 'ceph_packages':
    priority => '900',
    packages => '*apache2*',
    originator => 'InkTank',
    ensure => present,
  }
  ->
  class {'::apache':
    apache_version => $radosgw_apache_version,
  }
  include ::apache::mod::fastcgi
  include apache::mod::rewrite


  Package['radosgw'] -> Package[$::ceph::radosgw::params::http_service]
  File[$::ceph::radosgw::params::httpd_config_file] ~> Service[$::ceph::radosgw::params::http_service]
  
#  package { $radosgw_apache_deps:
#    ensure => $radosgw_apache_version,
#  }

 # file { $log_dir:
 #   ensure  => directory,
 #   owner   => $::ceph::radosgw::params::apache_user,
 #   group   => $::ceph::radosgw::params::apache_group,
 #   before  => Service[$::ceph::radosgw::params::http_service],
 #   mode    => '0751',
 #   require => Package['radosgw']
 # }

    file { $fastcgi_ext_script:
        ensure        => file,
        owner         => root,
        group         => $::ceph::radosgw::params::apache_group,
        mode          => 750,
	content	  	=> "#!/bin/sh\nexec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n client.radosgw.gateway",
        before  => File[$::ceph::radosgw::params::httpd_config_file],
	notify  => Service['httpd'],
    }

  file { $::ceph::radosgw::params::httpd_config_file:
    ensure  => file,
    owner   => $::ceph::radosgw::params::apache_user,
    group   => $::ceph::radosgw::params::apache_group,
    content => template('ceph/radosgw-apache.conf.erb'),
    before  => Service[$::ceph::radosgw::params::http_service],
    mode    => '0644',
    require => Package['radosgw'],
    notify  => Service['httpd'],
  }
  include apache::mod::proxy
  include apache::mod::proxy_http
  if $listen_ssl {
    include apache::mod::ssl

    if $radosgw_ca_file == undef {
      fail('The radosgw_ca parameter is required when listen_ssl is true')
    }

    if $radosgw_cert_file == undef {
      fail('The radosgw_cert parameter is required when listen_ssl is true')
    }

    if $radosgw_key_file == undef {
      fail('The radosgw_key parameter is required when listen_ssl is true')
    }

  }

}
