# This is a private type that should not be used directly.
define kairosdb::configure ($datastore,
  $jetty_port,
  $telnetserver_port,
  $properties_set,
  $properties_remove) {

  case $datastore {

    'cassandra': {

      kairosdb::property { "${name}.kairosdb.service.datastore":
        base_path => "${::kairosdb::conf_base}/${name}",
        key       => 'kairosdb.service.datastore',
        value     => 'org.kairosdb.datastore.cassandra.CassandraModule',
        before    => Exec["kairosdb-${name} configuration changed"],
        notify    => Exec["kairosdb-${name} configuration changed"],
      }

    }

    'h2': {

      kairosdb::property { "${name}.kairosdb.service.datastore":
        base_path => "${::kairosdb::conf_base}/${name}",
        key       => 'kairosdb.service.datastore',
        value     => 'org.kairosdb.datastore.h2.H2Module',
        before    => Exec["kairosdb-${name} configuration changed"],
        notify    => Exec["kairosdb-${name} configuration changed"],
      }

    }

    'remote': {

      kairosdb::property { "${name}.kairosdb.service.datastore":
        base_path => "${::kairosdb::conf_base}/${name}",
        key       => 'kairosdb.service.datastore',
        value     => 'org.kairosdb.datastore.remote.RemoteModule',
        before    => Exec["kairosdb-${name} configuration changed"],
        notify    => Exec["kairosdb-${name} configuration changed"],
      }

    }

    default: {
      fail("Illegal ::kairosdb::instance::datastore value '${datastore}'. Allowed values are 'cassandra' (default), 'h2' and 'remote'.")
    }

  }

  kairosdb::property { "${name}.kairosdb.query_cache.cache_dir":
    base_path => "${::kairosdb::conf_base}/${name}",
    key       => 'kairosdb.query_cache.cache_dir',
    value     => "${::kairosdb::tmpdir}/cairos_cache_${name}",
    before    => Exec["kairosdb-${name} configuration changed"],
    notify    => Exec["kairosdb-${name} configuration changed"],
  }

  kairosdb::property { "${name}.kairosdb.jetty.port":
    base_path => "${::kairosdb::conf_base}/${name}",
    key       => 'kairosdb.jetty.port',
    value     => $jetty_port,
    before    => Exec["kairosdb-${name} configuration changed"],
    notify    => Exec["kairosdb-${name} configuration changed"],
  }

  kairosdb::property { "${name}.kairosdb.telnetserver.port":
    base_path => "${::kairosdb::conf_base}/${name}",
    key       => 'kairosdb.telnetserver.port',
    value     => $telnetserver_port,
    before    => Exec["kairosdb-${name} configuration changed"],
    notify    => Exec["kairosdb-${name} configuration changed"],
  }

  if $properties_set != undef {

    validate_hash($properties_set)

    $keys_set = keys($properties_set)

    $keys_set.each |$key_set| {

      kairosdb::property { "${name}.${key_set}":
        base_path => "${::kairosdb::conf_base}/${name}",
        key       => $key_set,
        value     => $properties_set[$key_set],
        before    => Exec["kairosdb-${name} configuration changed"],
        notify    => Exec["kairosdb-${name} configuration changed"],
      }

    }

  }

  if $properties_remove != undef {

    validate_array($properties_remove)

    $properties_remove.each |$key_remove| {

      kairosdb::property { "${name}.${key_remove}":
        ensure    => 'absent',
        base_path => "${::kairosdb::conf_base}/${name}",
        key       => $key_remove,
        before    => Exec["kairosdb-${name} configuration changed"],
        notify    => Exec["kairosdb-${name} configuration changed"],
      }

    }

  }

  exec { "kairosdb-${name} configuration changed":
    command     => '/bin/true',
    path        => ['/sbin', '/bin', '/usr/sbin', '/usr/bin',
                '/usr/local/sbin', '/usr/local/bin'],
    refreshonly => true,
  }

}