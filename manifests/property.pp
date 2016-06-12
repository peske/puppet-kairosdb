# It is a private type and should not be used directly
define kairosdb::property (
  $base_path,
  $key,
  $ensure = 'present',
  $value = undef,
  $service_name = undef,
) {

  case $ensure {

    'present': {

      if $service_name != undef and $service_name != '' {

        augeas { "${name}_present":
          incl    => "${base_path}/conf/kairosdb.properties",
          changes => [ "set ${key} ${value}" ],
          lens    => 'Properties.lns',
          notify  => Service[$service_name],
        }

      }
      else {

        augeas { "${name}_present":
          incl    => "${base_path}/conf/kairosdb.properties",
          changes => [ "set ${key} ${value}" ],
          lens    => 'Properties.lns',
        }

      }

    }

    'absent': {

      if $service_name != undef and $service_name != '' {

        augeas { "${name}_absent":
          incl    => "${base_path}/conf/kairosdb.properties",
          changes => [ "rm ${key}" ],
          lens    => 'Properties.lns',
          notify  => Service[$service_name],
        }

      }
      else {

        augeas { "${name}_absent":
          incl    => "${base_path}/conf/kairosdb.properties",
          changes => [ "rm ${key}" ],
          lens    => 'Properties.lns',
        }

      }

    }

    default: {
      fail("Incorrect kairosdb::property::ensure value '${ensure}'. Allowed values are 'present' (default) and 'absent'.")
    }

  }

}