[![Build Status](https://travis-ci.org/crayfishx/network_config.svg?branch=master)](https://travis-ci.org/crayfishx/network_config)

# network_config

#### Table of Contents

1. [Types and providers](#types-and-providers)
2. [Configuring the network_config module)](#configuring-the-network_config-module)



### Introduction 

This module takes a rather complex set of hiera data to manage network infrastructures on Network Manager based systems (eg: RHEL7).  It supports:

* A type and provider to manage network interfaces
* A type and provider to manage IP allocations
* Set of Puppet classes to manage network infrastructures from hiera data

This module manages the interface configuration files in `/etc/sysconfig/network-scripts`, as well as starting and stopping interfaces.

You can choose just to use the [Types and providers](#types-and-providers) that this module exposes, `network_interface` and `ip_allocation` and wrap these into your own module.  Or the [puppet module can be used](#Configuring-the-network_config-module) to define complex network infrastructures in Hiera.


### OS Support

The only officially supported OS for this module right now is RedHat/CentOS 7.0 - support for RHEL6 is limited and not very well tested at this time.

## Types and providers

### `network_interface`

#### Example

```puppet
network_interface { 'ens33':
  ensure    => 'present',
  bootproto => 'static',
  device    => 'ens33',
  ipv6init  => 'yes',
  netboot   => 'yes',
  onboot    => 'yes',
  type      => 'Ethernet',
}
```

#### Description and parameters

This type takes an interface name as a title and configures the interface in `/etc/sysconfig/network-scripts/ifcfg-<name>`  See the [configuration parameter reference](#configuration-parameter-reference) for a complete list of configurable parameters that this type accepts.

### `ip_allocation`

#### Example

```puppet
ip_allocation { '192.168.193.3':
  ensure    => 'present',
  gateway   => '192.168.193.100',
  interface => 'ens33',
  prefix    => '24',
}
```

#### Description and parameters

This type takes an IP address as the resource title.  Supported parameters are:

| Parameter       | Description                  |
| ---------       | -----------                  |
| `ensure`        | `present` or `absent`        |
| `interface`     | The interface name this allocation is assigned to |
| `prefix`        | The prefix (CIDR notation) of the IP address |
| `netmask`       | The netmask of the IP address (eg: 255.255.255.0) |
| `gateway`       | The gateway for this IP allocation |

Note that only one of `prefix` or `netmask` should be used.

Multiple IP addresses bound to the same interface will be configured with their numerical identifier (eg: `IPADDR0`, `PREFIX0`, `IPADDR1`, `PREFIX1`, `IPADDR2`, `PREFIX2`...etc).  The provider also ensures that when removing an IP allocation for an interface that all the numerican identifiers are re-sorted if there are gaps in the sequence, since Network Manager will not read beyond the first gap.

IP addresses are considered unique, therefore changing the `interface` parameter will have the effect of moving the IP allocation from one interface to another

```
Network_config::Ifconfig[ens99]/Ip_allocation[10.7.6.10]/interface: interface changed 'ens39' to 'ens99'
```

### Purging

Both `network_interface` and `ip_allocation` are purgable resources, meaning they support the `instances()` method.  We recommend using the [crayfishx/purge](https://forge.puppet.com/crayfishx/purge) module as it offers more finite control over purging, for example, to purge all unmanaged IP allocations, except the loopback interface, you could do something like

```puppet
purge { 'ip_allocation':
  unless => [ 'interface', '==', 'lo' ],
}
```

For purging all interfaces and ip_allocations you can also set the `purge_interfaces` and `purge_ip_allocations` options on the `network_config` class.  When using these options, any interfaces with a `name` or `device` matching an entry in `exclude_if`, plus any IP allocations with an `interface` matching an entry in `exclude_if` will *not* be purged.   (NOTE: make sure you are running crayfishx/purge >= 1.1.0).  As a further precaution, an ip_allocation of `127.0.0.1` will never be purged by the class.



## Configuring the network_config module

### Contents

1. [Usage](#usage)
2. [Parameters](#parameters)
3. [Configuration using hiera](#configuring-using-hiera)
4. [Bonding](#bonding)

### Usage

The module is designed to get most of it's configuration from data lookups.   To invoke the module, simply include it

```
class { 'network_config': }
```


### Parameters

| Parameter       | Description                  | Default   |
| ---------       | -----------                  | -------   |
| `interfaces`      | [Interfaces to configure](#network_configinterfaces) | `interfaces` fact |
| `interface_names` | [Mapping of interfaces to type names](#network_configinterface_names) | n/a |
| `defaults`        | [Defaults for each interface type](#network_configdefaults) | n/a |
| `vlans`           | [VLAN specific configuration](#network_configvlans) | n/a |
| `ifconfig`        | [Host specific interface configuration](#network_configifconfig) | n/a |
| `bonds`           | [Bond interfaces and specific configuration](#bonding) | {} |
| `exclude_if`      | List of interfaces to exclude from management, even if `interfaces` has them | lo |
| `networkmanager`  | True or false, is NetworkManager enabled (to be deprecated) | RHEL7 true, RHEL6 false |
| `purge_interfaces` | True or false, whether or not to purge non managed interfaes (this will completely remove the ifcfg-<interface> file for interfaces not being managed by Puppet.  Any interface matching a device name of `lo` or a name of `loopback`  will not be purged | false |
| `purge_ip_allocations` | True or false, whether or not to purge unmanaged IP addresses, an IP address matching `127.0.0.1` or with the interface `lo` will not be purged | false |
| `restart_service`* | Whether or not to restart the network service on change | true |
| `restart_interface`* | Whether or not to restart the affected network interface on change | false |

 _* only one of restart_interface or restart_service can be defined_


### Configuration using hiera


#### `network_config::interfaces`

This setting is a list of interfaces that we want to configure on the system.  If it is not set then the module will use the output of the `interfaces` fact.  To override this, we can give a comma separated list of the interfaces that we want to manage.  Eg:

```yaml
network_config::interfaces: eth0,eth1,eth2
```

Note that this is a comma separated _string_, with no spaces.  Not an array.

#### `network_config::interface_names`

The first thing that should be configured are interface names.  We define interface configuration parameters against interface _types_, that is, instead of saying `eth0`, `eth1`...etc, we assign friendly names to these interfaces and refer to them by the type of interface they are, eg: management.  For each interface we want to manage we assign it a type, eg:

```yaml
network_config::interface_names:
  eth0: management
  eth1: application
  eth2: backup
```

#### `network_config::defaults`

Now that we have our interface type names deifined in `interface_names` we can add some global defaults to each of these interface types.  We have the opportunity to override these in specific circumstances, but things that are generally global such as domain, can be configured as defaults.  Eg:

```yaml
network_config::defaults:
  management:
    bootproto: "none"
    defroute: "no"
    dns1: 10.0.8.2
    dns2: 10.0.8.3
    domain: enviatics.com
    onboot: "yes"
  backup:
    bootproto: "none"
    defroute: "no"
    dns1: 10.0.0.2
    dns2: 10.0.0.3
    domain: enviatics.com
    interface_type: "Ethernet"
    onboot: "yes"
  application:
    bootproto: "none"
    defroute: "no"
    dns1: 10.0.6.2
    dns2: 10.0.6.3
    domain: app.enviatics.com
    onboot: "yes"
```

See the configuration parameter appendix for a list of supported parameters.

#### `network_config::vlans`

This setting gives us specific control to add configuration or override defaults for different vlans. Eg:

```yaml
network_config::vlans:
  100:
    prefix: 24
    gateway: 10.0.8.1
  200:
    prefix: 32
    gateway: 10.0.0.1
  300:
    prefix: 24
    gateway: 10.0.6.3
```

Note that any configuration parameter can be overriden here for a specific vhost, eg:

```yaml
network_config::vlans:
  100:
    prefix: 24
    gateway: 10.0.8.1
    domain: vlan_100.enviatics.com
```

#### `network_config::ifconfig`

The `ifconfig` setting would normally be configured at the host level in your lookup hierarchy, and it's this parameter which ties together and inherits all of the above default settings.  `ifconfig` is a hash of interface types and configuration parameters, it accepts any configuration parameter as a host specific override, as well as `vlan` to inherit configuration parameters from the VLAN is belongs to.  A simple example would be:

```yaml
network_config::ifconfig:
  application:
    ipaddr: 10.0.8.101
    vlan: 100
```

The above configuration will get all the default configuration for a management interface type, the gateway and prefix parameters inherited from the assigned VLAN and we are specifying the IP address specific to this host.

Like the other options, you can override any configuration parameter at this level and it will take priority, eg:

```yaml
network_config::ifconfig:
  application:
    ipaddr: 10.0.8.101
    vlan: 100
    gateway: 10.0.8.254
```

This will override the VLAN default and set the gateway to .254

The `ipaddr` parameter can also take an array

```yaml
network_config::ifconfig:
  applciation:
    ipaddr:
      - 10.0.8.101
      - 10.0.8.102
    vlan: 100
```
 
In the above example we will end up with a configuration file that contains

```
IPADDR0=10.0.8.101
GATEWAY0=10.0.8.1
PREFIX0=24

IPADDR1=10.0.8.102
GATEWAY1=10.0.8.1
PREFIX1=24
```

Note that the `PREFIX` and `GATEWAY` in this example were automatically worked out, as they are inherited from the VLAN that the interface has been assigned to.

#### Override priorities

When evaluating the configuration, the module will prioritise duplicate settings top down in the following order (first has highest priority/win)

* `network_config::ifconfig`
* `network_config::vlans` (if supplied to `network_config::ifconfig`)
* `network_config::bonds` (see below)
* `network_config::defaults` for the specific type of interface being configured.


### Bonding

If you need to bond multiple interfaces for a particular interface type you can follow much of the same procedure... firstly we create an additional network interface type for bond interface defaults, the name does not matter.  Eg:

```yaml
network_config::defaults
  ...
  bond_interface:    
    bootproto: "none"
    defroute: "no"
    onboot: "yes"
```

Next we assign two interfaces that we want to be the bound interface slaves.  We also define a new interface that will be our `bond0` and we can give it an interface type like we did earlier, eg:

```yaml
network_config::interface_names:
  ...
  eth3: bond_interface
  eth4: bond_interface
  bond0: application
```

This will configure `bond0` as an application interface inheriting all of our defaults from that type.  We also have `eth3` and `eth3` configured with general bonding defaults.

The final step is to define which real interfaces are slaves of which bond interfaces, we do this with the `bonds` parameter.

```yaml
network_config::bonds:
  bond0:
    interfaces:
      - eth3
      - eth4
```

The above will make sure that `eth3` and `eth4` interfaces are configured as slaves of `bond0` with

```
NAME=ens51
MASTER=bond0
SLAVE=yes
```

... aswell as all the inherited configuration from the `bond_interface` type.

The `bonds` hash can also contain other bond specific configuration to apply to the bond interface (`bond0` in our example). Eg:

```yaml
network_config::bonds:
  bond0:
    bonding_opts: 'miimon=100 mode=1'
    interfaces:
      - eth3
      - eth4
```

will configure in `bond0`

```
BONDING_OPTS=miimon=100 mode=1
```


## Configuration parameter reference

| Parameter | NM configured option | |
| --------- | -------------------- | ------ |
| netmask  | NETMASK | |
| bootproto  | BOOTPROTO  | |
| defroute  | DEFROUTE  | | 
| ipv4_failure_fatal | IPV4_FAILURE_FATAL  |  |
| ipv6init | IPV6INIT  |   |
| ipv6_autoconf | IPV6_AUTOCONF  |   |
| ipv6_defroute | IPV6_DEFROUTE  |   |
| ipv6_failure_fatal | IPV6_FAILURE_FATAL  |   |
| uuid | UUID  |   |
| onboot | ONBOOT   |   |
| dns1 |  DNS1  | |
| dns2 |  DNS2  | |
| domain | DOMAIN  |  |
| hwaddr | HWADDR  |   |
| ipv6_peerdns | IPV6_PEERDNS  |   |
| ipv6_peerroutes | IPV6_PEERROUTES  |   |
| zone | ZONE  |   |
| type | TYPE  | network_interface type param only  |
| interface_type | TYPE  | Hiera config only  |
| device | DEVICE   |   |
| bonding_opts | BONDING_OPTS  |   |
| bonding_master | BONDING_MASTER |   |
| master | MASTER  |   |
| slave | SLAVE  |   |
| netboot  | NETBOOT  |   |
| nm_controlled | NM_CONTROLLED  |   |


## Author

* Written and maintained by Craig Dunn <craig@craigdunn.org> @crayfishx
* Sponsered by Baloise Group [http://baloise.github.io](http://baloise.github.io)
