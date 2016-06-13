# == Class: kairosdb::instance
#
#  Installs and prepares KairosDB. 
#
# === Parameters
#
# [*version*]
#   KairosDB version that will be installed, or that
#   is already present if manage_package is false.
#   Default:   1.1.1-1
#
# [*manage_package*]
#   Should the class manage (install) KairosDB package
#   or not.
#   Default:   true
#
# [*package_name*]
#   KairosDB package name.
#   Default:   'kairosdb'
#
# [*package_ensure*]
#   Used only if manage_package is true. The value will
#   be usod for ensure parameter of package resource.
#   Default:   'present'
#
# [*install_dir*]
#   KairosDB installation directory.
#   IMPORTANT: The value will not change package default
#              installation directory. Instead it only 
#              informs kairosdb class where to look for
#              installed files.
#   Default:   '/opt/kairosdb'
#
# [*conf_base*]
#   Directory that will store configurations of all
#   KairosDB instances installed. Each instance will
#   its own subdirectory within this directory.
#   Default:   '/etc/kairosdb'
#
# [*tmpdir*]
#   The directory that will be used for KairosDB query
#   cache. Every installed KairosDB instance will have
#   its own subdirectory within this directory.
#   Default:   '/tmp'
#
# [*patch_initd*]
#   Should KairosDB init.d script should be patched or not.
#   It is known issue with KairosDB service script:
#   (https://github.com/kairosdb/kairosdb/issues/239)
#   If this parameter is set to true than the script will
#   be fixed, and will work as expected. 
#   IMPORTANT: Used only on Debian / Ubuntu OS. Ignored on
#              RedHat / CentOS.
#   Default:   true
#
# [*init_functions*]
#   Absolute location of init-functions file. This
#   parameter is used only if patch_initd is set to true. 
#   Default:   '/lib/lsb/init-functions'
#
# [*use_highcharts*]
#   Whether Highcharts should be installed or not.
#   IMPORTANT: Higcharts is a commercial product and
#              an appropriate license is needed for its
#              usage. 
#   Default:   false
#
# [*highcharts_acknowledge*]
#   When use_highcharts is set to true, puppet agent will
#   generate a warning that it is a commercial product
#   at every run. By using this parameter you can disable
#   these warnings. To do so you need to set the following
#   value:
#   'I am aware that highcharts.js is a commercial product, and that an appropriate license is needed for its usage.'
#   Default:   undef
#
# === Example
#
#  kairosdb::instance { 'kairosdb1': }
#
# === Authors
#
# Author Name: Fat Dragon www.itenlight.com
#
# === Copyright
#
# Copyright 2016 IT Enlight
#
class kairosdb (
  $version = '1.1.1-1',
  $manage_package = true,
  $package_name = 'kairosdb',
  $package_ensure = 'present',
  $install_dir = '/opt/kairosdb',
  $conf_base = '/etc/kairosdb',
  $tmpdir = '/tmp',
  $patch_initd = true,
  $init_functions = '/lib/lsb/init-functions',
  $use_highcharts = false,
  $highcharts_acknowledge = undef,
  ){

  # Validate input
  validate_bool($manage_package)
  validate_bool($patch_initd)
  validate_bool($use_highcharts)

  if $manage_package {
    
    include '::staging'

    validate_re($version, '^(\d+\.\d+\.\d+)(?:-\d+)?$')
    
    $release = regsubst($version, '^([^-]+).*$', '\1')

    case $::osfamily {

      'RedHat': {

        staging::file { "kairosdb-${version}.rpm":
          source => "https://github.com/kairosdb/kairosdb/releases/download/v${release}/kairosdb-${version}.rpm",
        }
        ->
        package { $package_name:
          ensure   => $package_ensure,
          source   => "${::staging::path}/kairosdb/kairosdb-${version}.rpm",
          provider => 'rpm',
        }

      }

      'Debian': {

        staging::file { "kairosdb_${version}_all.deb":
          source => "https://github.com/kairosdb/kairosdb/releases/download/v${release}/kairosdb_${version}_all.deb",
        }
        ->
        package { $package_name:
          ensure   => $package_ensure,
          source   => "${::staging::path}/kairosdb/kairosdb_${version}_all.deb",
          provider => 'dpkg',
        }

      }

      default:  {
        fail("Unsported ::osfamily '${::osfamily}'. Only 'RedHat' and 'Debian' are supported.")
      }

    }

    file { $conf_base:
      ensure  => 'directory',
      require => Package[$package_name],
    }
    
  }
  else {

    file { $conf_base:
      ensure => 'directory',
    }
    
  }

  kairosdb::serviceinstaller { 'kairosdb':
    ensure => 'absent', 
  }
  
  file { "${::kairosdb::tmpdir}/kairos_cache":
    ensure  => 'absent',
    force   => true,
    require => Kairosdb::Serviceinstaller['kairosdb'],
  }

  file { "${conf_base}/template":
    ensure  => 'directory',
    require => File["${::kairosdb::tmpdir}/kairos_cache"],
  }

  exec { 'kairosdb_config_template_bin':
    command => "cp -r ${install_dir}/bin ${conf_base}/template/",
    path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin',
                '/usr/local/sbin', '/usr/local/bin'],
    unless  => "test -d ${conf_base}/template/bin",
    require => File["${conf_base}/template"],
  }

  file_line { 'check-log-errors-logFile':
    line    => "logFile=${conf_base}/<instance_name>/log/kairosdb.log",
    path    => "${conf_base}/template/bin/check-log-errors.sh",
    match   => '^\s*logFile=',
    after   => Exec['kairosdb_config_template_bin'],
    require => File["${conf_base}/template"],
  }

  file_line { 'check-log-errors-positionFile':
    line    => "positionFile=${conf_base}/<instance_name>/tmp/.checkLogPosition",
    path    => "${conf_base}/template/bin/check-log-errors.sh",
    match   => '^\s*positionFile=',
    after   => Exec['kairosdb_config_template_bin'],
    require => File["${conf_base}/template"],
  }

  file_line { 'kairosdb-KAIROSDB_LIB_DIR':
    line    => "KAIROSDB_LIB_DIR=\"${install_dir}/lib\"",
    path    => "${conf_base}/template/bin/kairosdb.sh",
    match   => '^\s*KAIROSDB_LIB_DIR=',
    after   => Exec['kairosdb_config_template_bin'],
    require => File["${conf_base}/template"],
  }

  file_line { 'kairosdb-KAIROS_PID_FILE':
    line    => '  KAIROS_PID_FILE=/var/run/kairosdb-<instance_name>.pid',
    path    => "${conf_base}/template/bin/kairosdb.sh",
    match   => '^\s*KAIROS_PID_FILE=',
    after   => Exec['kairosdb_config_template_bin'],
    require => File["${conf_base}/template"],
  }

  file_line { 'kairosdb-service-KAIROS_PID_FILE':
    line    => 'export KAIROS_PID_FILE="/var/run/kairosdb-<instance_name>.pid"',
    path    => "${conf_base}/template/bin/kairosdb-service.sh",
    match   => '^\s*export\s+KAIROS_PID_FILE=',
    after   => Exec['kairosdb_config_template_bin'],
    require => File["${conf_base}/template"],
  }

  file_line { 'kairosdb-service-KAIROS_SCRIPT_PATH':
    line    => "KAIROS_SCRIPT_PATH=\"${conf_base}/<instance_name>/bin/kairosdb.sh\"",
    path    => "${conf_base}/template/bin/kairosdb-service.sh",
    match   => '^\s*KAIROS_SCRIPT_PATH=',
    after   => Exec['kairosdb_config_template_bin'],
    require => File["${conf_base}/template"],
  }

  if $::osfamily == 'Debian' {

    if $patch_initd {

      file_line { 'kairosdb-service-PATCH_INITD':
        line    => "        . ${init_functions} ; pidofproc -p /var/run/kairosdb-<instance_name>.pid java >/dev/null ; status=\$? ; if [ \$status -eq 0 ]; then log_success_msg \"kairosdb-<instance_name> is running.\" ; else log_failure_msg \"kairosdb-<instance_name> is not running.\" ; fi ; exit \$status",
        path    => "${conf_base}/template/bin/kairosdb-service.sh",
        match   => '^\s*status\s+kairosdb\s*$',
        after   => Exec['kairosdb_config_template_bin'],
        require => File["${conf_base}/template"],
      }

    }
    else {

      file_line { 'kairosdb-service-PATCH_INITD':
        line    => '        status kairosdb',
        path    => "${conf_base}/template/bin/kairosdb-service.sh",
        match   => '^.*(?:(status\s+kairosdb\s*)|(.*pidofproc\s+-p\s.+))$',
        after   => Exec['kairosdb_config_template_bin'],
        require => File["${conf_base}/template"],
      }

    }

  }

  exec { 'kairosdb_config_template_conf':
    command => "cp -r ${install_dir}/conf ${conf_base}/template/",
    path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin',
                '/usr/local/sbin', '/usr/local/bin'],
    unless  => "test -d ${conf_base}/template/conf",
    require => File["${conf_base}/template"],
  }
  ->
  kairosdb::property { 'template.kairosdb.jetty.static_web_root':
    base_path => "${conf_base}/template",
    key       => 'kairosdb.jetty.static_web_root',
    value     => "${install_dir}/webroot",
    require   => File["${conf_base}/template"],
  }

  if $use_highcharts {

    if $highcharts_acknowledge != 'I am aware that highcharts.js is a commercial product, and that an appropriate license is needed for its usage.' {
      
      notify {'highcharts.js is a commercial product, and an appropriate license is needed for its usage.':
        loglevel => 'warning',
      }

    }

    staging::file { 'highcharts.js':
      source  => 'http://code.highcharts.com/highcharts.js',
      require => File["${conf_base}/template"],
    }
    
    file { "${install_dir}/webroot/js/highcharts.js":
      ensure  => 'file',
      source  => "${::staging::path}/kairosdb/highcharts.js",
      require => Staging::File['highcharts.js'],
    }

    file_line {'highcharts_js_index_html':
      line    => '  <script src="js/highcharts.js"></script>',
      path    => "${install_dir}/webroot/index.html",
      match   => '^\s*(?:<!--)?\s*<script\ssrc=\"js/highcharts\.js\"></script>\s*(?:-->)?\s*$',
      require => File["${install_dir}/webroot/js/highcharts.js"],
    }

    file_line {'highcharts_js_view_html':
      line    => '  <script src="js/highcharts.js"></script>',
      path    => "${install_dir}/webroot/view.html",
      match   => '^\s*(?:<!--)?\s*<script\ssrc=\"js/highcharts\.js\"></script>\s*(?:-->)?\s*$',
      require => File["${install_dir}/webroot/js/highcharts.js"],
    }

  }
  else {

    file { "${install_dir}/webroot/js/highcharts.js":
      ensure  => 'absent',
      require => File["${conf_base}/template"],
    }

    file_line {'highcharts_js_index_html':
      line    => '  <!--<script src="js/highcharts.js"></script>-->',
      path    => "${install_dir}/webroot/index.html",
      match   => '^\s*(?:<!--)?\s*<script\ssrc=\"js/highcharts\.js\"></script>\s*(?:-->)?\s*$',
      require => File["${install_dir}/webroot/js/highcharts.js"],
    }

    file_line {'highcharts_js_view_html':
      line    => '  <!--<script src="js/highcharts.js"></script>-->',
      path    => "${install_dir}/webroot/view.html",
      match   => '^\s*(?:<!--)?\s*<script\ssrc=\"js/highcharts\.js\"></script>\s*(?:-->)?\s*$',
      require => File["${install_dir}/webroot/js/highcharts.js"],
    }

  }

}