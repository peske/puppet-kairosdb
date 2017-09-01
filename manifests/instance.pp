# == Class: kairosdb::instance
#
#  Creates and configures (or removes) KairosDB instance.
#
# === Parameters
#
# [*name*]
#   The name of KairosDB instance.
#   Default:   N/A (mandatory)
#
# [*ensure*]
#   Determines if the instance should be created ('present')
#   or removed ('absent').
#   IMPORTANT: Removing an instance will not remove its
#              Cassandra storage. If H2 storage is used
#              it might be removed, depending on its location.
#   Default:   'present'
#
# [*manage_service*]
#   Should the service should be managed by this class or not.
#   Default:   true
#
# [*service_ensure*]
#   Used only if manage_service is true. The value is passed
#   to ensure parameter of service resource.
#   Default:   'running'
#
# [*service_enable*]
#   Used only if manage_service is true. The value is passed
#   to enable parameter of service resource.
#   Default:   true
#
# [*telnetserver_port*]
#   Telnet port used by the instance. Should be unique on
#   the system, of course.
#   Default:   4242
#
# [*jetty_port*]
#   Jetty (HTTP) port used by the instance. Should be unique
#   on the system, of course.
#   Default:   8080
#
# [*datastore*]
#   Datastore to be used by the instance. Acceptable values
#   are: 'cassandra', 'h2' and 'remote'
#   Default:   'cassandra'
#
# [*properties_set*]
#   Hash of kairosdb.properties key-value pairs that should
#   be set for the instance
#   Default:   undef
#
# [*properties_remove*]
#   Array of kairosdb.properties keys that should be removed
#   from kairosdb.properties configuration file.
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
define kairosdb::instance(
  $ensure = 'present',
  $manage_service = true,
  $service_ensure = 'running',
  $service_enable = true,
  $telnetserver_port = 4242,
  $jetty_port = 8080,
  $datastore = 'cassandra',
  $properties_set = undef,
  $properties_remove = undef,
  ) {

  include '::kairosdb'
  require '::kairosdb'

  validate_bool($manage_service)
  validate_bool($service_enable)
  validate_integer($telnetserver_port)
  validate_integer($jetty_port)

  case $ensure {

    'absent': {

      kairosdb::serviceinstaller { "kairosdb-${name}":
        ensure => 'absent',
      }

      file { "kairosdb-${name} directory":
        ensure  => 'absent',
        path    => "${::kairosdb::conf_base}/${name}",
        force   => true,
        require => Kairosdb::Serviceinstaller["kairosdb-${name}"],
      }

    }

    'present': {

      exec { "kairosdb-${name} directory":
        command => "cp -r ${::kairosdb::conf_base}/template ${::kairosdb::conf_base}/${name} && sed -i 's/<instance_name>/${name}/g' ${::kairosdb::conf_base}/${name}/bin/*",
        path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin',
                    '/usr/local/sbin', '/usr/local/bin'],
        creates => "${::kairosdb::conf_base}/${name}/bin/kairosdb.sh",
      }

      kairosdb::serviceinstaller { "kairosdb-${name}":
        ensure     => 'present',
        scriptfile => "${::kairosdb::conf_base}/${name}/bin/kairosdb-service.sh",
        require    => Exec["kairosdb-${name} directory"],
      }
      ->
      kairosdb::configure { $name:
        datastore         => $datastore,
        jetty_port        => $jetty_port,
        telnetserver_port => $telnetserver_port,
        properties_set    => $properties_set,
        properties_remove => $properties_remove,
      }

      if $manage_service {

        service { "kairosdb-${name}":
          ensure    => $service_ensure,
          enable    => $service_enable,
          subscribe => Exec["kairosdb-${name} configuration changed"],
          require   => Kairosdb::Configure[$name],
        }

      }

    }

    default:  {
      fail("Invalid ::kairosdb::instance::ensure value '${ensure}'. Valid values are 'present' (default) and 'absent'.")
    }

  }

}