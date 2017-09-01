# Private type. You shouldn't use it directly.
define kairosdb::serviceinstaller ($ensure, $scriptfile = undef) {

  case $ensure {

    'present': {

      case $::osfamily {

        'RedHat': {

          $servicecommand = "chkconfig --add ${name}"

        }

        'Debian': {

          $servicecommand = "update-rc.d ${name} defaults"

        }

        default: {
          fail("Unsupported ::osfamily '${::osfamily}'. Supported values are 'RedHat' and 'Debian'.")
        }

      }

      file { "/etc/init.d/${name}":
        ensure => 'file',
        source => "file://${scriptfile}",
        mode   => '0755',
        notify => Exec["${name} service installer"],
      }

      exec { "${name} service installer":
        command     => $servicecommand,
        path        => ['/sbin', '/bin', '/usr/sbin', '/usr/bin',
                    '/usr/local/sbin', '/usr/local/bin'],
        refreshonly => true,
      }

    }

    'absent': {

      case $::osfamily {

          'RedHat': {

            $servicecommand = "chkconfig --del ${name}"

          }

          'Debian': {

            $servicecommand = "update-rc.d -f ${name} remove"

          }

          default: {
            fail("Unsupported ::osfamily '${::osfamily}'. Supported values are 'RedHat' and 'Debian'.")
          }

      }

      exec { "service ${name} stop":
        path   => ['/sbin', '/bin', '/usr/sbin', '/usr/bin',
                    '/usr/local/sbin', '/usr/local/bin'],
        onlyif => "service ${name} status",
      }
      ->
      exec { "${name} service installer":
        command => $servicecommand,
        path    => ['/sbin', '/bin', '/usr/sbin', '/usr/bin',
                    '/usr/local/sbin', '/usr/local/bin'],
        onlyif  => "test -f /etc/init.d/${name}",
      }
      ->
      file { "/etc/init.d/${name}":
        ensure => 'absent',
      }

    }

    default: {
      fail("Invalid ::kairosdb::serviceinstaller::ensure value '${ensure}'. Valid values are 'present' and 'absent'.")
    }

  }

}