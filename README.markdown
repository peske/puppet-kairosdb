# kairosdb Puppet Module #

The module installs [KairosDB](http://kairosdb.github.io/) and allows configuring and managing multiple KairosDB instances on the same Ubuntu host.

The module is simple to implement and use, and complete (still short) documentation can be found at [Puppet and KairosDB - kairosdb Module](https://www.itenlight.com/blog/2016/06/12/Puppet+and+KairosDB+-+kairosdb+Module).

## Existing KairosDB Implementations

If you already have KairosDB up and running, **you should not implement this module** before checking [the original documentation](https://www.itenlight.com/blog/2016/06/12/Puppet+and+KairosDB+-+kairosdb+Module). The reason is that the module introduces slightly different, instance-based way of managing KairosDB service, and if it finds service called "kairosdb" - it will stop it and remove it.

## Why Another KairosDB Module?

It is true that one KairosDB module already can be found at [puppet forge](https://forge.puppet.com/jmkeyes/kairosdb), but there are few things that I couldn't accomplish using it:

* Although the mentioned module correctly installs KairosDB, due to [an issue in KairosDB itself](https://github.com/kairosdb/kairosdb/issues/239) the module is not able to manage KairosDB service on Ubuntu. This module implements simple patch (`patch_initd`) that resolves the problem.
* Default KairosDB installation (implemented by the mentioned module) does not allow running multiple KairosDB instances on the same host, and this is exactly what I wanted to do.

Don't get me wrong - [jmkeyes/kairosdb](https://forge.puppet.com/jmkeyes/kairosdb) module is great, and obviously both mentioned _cons_ are not caused by the module, but by KairosDB itself. Anyway I really wanted to have these issues resolved, so I've created this module which besides pure installation also _patches_ few things.

## Minimum Configuration

Minimum configuration example is based on assumption that we'll use Cassandra cluster as datastore, with two Cassandra nodes: 192.168.1.1:9160 and 192.168.1.2:9160. If so we can configure one KairosDB instance as follows:

```
kairosdb::instance { 'kdb01': 
  properties_set => {
    'kairosdb.datastore.cassandra.host_list' => '192.168.1.1:9160, 1192.168.1.2:9160', 
  }
}
```

## More Configuration Examples

### Two Instances Example

As mentioned above, the module supports multiple KairosDB instances at the same host. Here's an example:

```
kairosdb::instance { 'kdb01': 
  properties_set => {
    'kairosdb.datastore.cassandra.host_list' => '192.168.1.1:9160, 1192.168.1.2:9160', 
  }
}
kairosdb::instance { 'kdb02': 
  telnetserver_port => 4243, 
  jetty_port        => 8081, 
  properties_set => {
    'kairosdb.datastore.cassandra.host_list' => '192.168.1.1:9160, 1192.168.1.2:9160', 
  }
}
```

**Note** that while configuring the second instance we have to specify different ports at least.

You've might noticed that the previous example is not too useful since both instances are running on the same host, and both are targeting the same datastore (database). It's true. But the beauty of the module is in the fact that it allows us completely independent configuration of the instances, so we can accomplish what ever we want. Let's enumerate some of possibilities:

* The instances can target the same Cassandra cluster, or different clusters;
* The instances can target the same keyspace in the Cassandra cluster, or different keyspaces;
* If the instances are targeting different keyspace we can differently configure these keyspaces. For example one (less important) keypace can be created with replication_factor 1, while another (more important) with replication_factor=3.
* The instances do not have to target the same datastore type, meaning that one instance can target Cassandra, while another targets H2.
* etc.

Obviously any combination is possible, and you can read more at [Puppet and KairosDB - kairosdb Module](https://www.itenlight.com/blog/2016/06/12/Puppet+and+KairosDB+-+kairosdb+Module).

## Host-Level Configuration

There's one restriction in configuring instances: all the instances have to use the same KairosDB version (the same package). The module does not support running multiple KairosDB versions side-by-side. 

Host-level configuration (including KairosDB version for example) is covered by `kairosdb` class. Here's a complete configuration example:

```
class { 'kairosdb': 
  version => '1.1.1-1', 
}
kairosdb::instance { 'kdb01': 
  properties_set => {
    'kairosdb.datastore.cassandra.host_list' => '192.168.1.1:9160, 1192.168.1.2:9160', 
  }
}
kairosdb::instance { 'kdb02': 
  telnetserver_port => 4243, 
  jetty_port        => 8081, 
  properties_set => {
    'kairosdb.datastore.cassandra.host_list' => '192.168.1.1:9160, 1192.168.1.2:9160', 
  }
}
```

**Note:** If `kairosdb` class is not explicitly specified (as in the first few examples), the default one (with default parameters) is assumed.

## Parameters

To avoid repetition I haven't specified all the parameters here, but you can find the complete list with explanations at [Puppet and KairosDB - kairosdb Module](https://www.itenlight.com/blog/2016/06/12/Puppet+and+KairosDB+-+kairosdb+Module).

## Feedback

Guys, it's my fourth module at puppet forge, almost 2000 downloads in total so far, still no single comment, question, etc. Sometimes I think that actually some bot downloads the modules. Your feedback is really important, and you can provide some at [puppet forge](https://forge.puppet.com/fatdragon/kairosdb), [Github](https://github.com/peske/puppet-kairosdb/issues), or [project page](https://www.itenlight.com/blog/2016/06/12/Puppet+and+KairosDB+-+kairosdb+Module) - **please do that**. I'm eager to hear not only compliments but criticism also.

## License

This module is published under Apache 2.0 license, but depending on `use_highcarts` parameter value it might include [Highcart script](http://www.highcharts.com/), which is a **commercial** product, and you should check [their licensing options](http://shop.highcharts.com/highcharts/). They offer free license for non-commercial usage.

## Release History

### v0.1.0

**Date:** Jun 12. 2016

**Release Info:**
* Initial release.