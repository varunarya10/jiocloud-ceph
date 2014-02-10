# these parameters need to be accessed from several locations and
# should be considered to be constant
class ceph::radosgw::params {


  case $::osfamily {
    'RedHat': {
      $http_service                = 'httpd'
      $http_modfastcgi                = 'mod_fastcgi'
      $httpd_config_file           = '/etc/httpd/conf.d/ceph-radosgw.conf'
      $httpd_listen_config_file    = '/etc/httpd/conf/httpd.conf'
      $root_url                    = '/radosgw'
      $apache_user                 = 'apache'
      $apache_group                = 'apache'
    }
    'Debian': {
      $http_service                = 'apache2'
      $httpd_config_file           = '/etc/apache2/conf.d/ceph-radosgw.conf'
      $httpd_listen_config_file    = '/etc/apache2/ports.conf'
      $root_url                    = '/radosgw'
      case $::operatingsystem {
        'Debian': {
            $apache_user           = 'www-data'
            $apache_group          = 'www-data'
        }
        default: {
            $apache_user           = 'radosgw'
            $apache_group          = 'radosgw'
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
