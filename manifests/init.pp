# == Class: network_config
#
# This is a bespoke network configuration module for managing sysconfig
# interface settings on RHEL.  
# 
# We don't want to manage the entire file with a template (like example42/network)
# as there are some pre-filled values such as UUID and HWADDR that we don't want
# to manage but we still want the values left in the file, so using a template
# is not the best solution.  This module uses ini_setting to manage individual
# lines within the files and leave precofigured and unmanaged values alone.
#
# Furthermore, we know 95% of the time that the interface names will be the same
# across the estate and that they represent different VLAN functions (app,
# management...etc), so we don't want to have to pollute hiera with lots of
# repetition of the interface names, but they still need to be configurable
# for edge cases.  This module uses a couple of hiera structures (see below)
# to assign interface names a "type" and allow for generic configurable
# defaults for those interface types thus allowing for per-host specific
# configuration to be as simple, readable and uncomplicated as possible for
# the user.
#
# 
# === Parameters
#
#
# [*interfaces*]
#   A comma separated list of configured interfaces, this is populated by
#   default from the $::interfaces fact.  Eg: eno16780032,eno33559296,lo
#
# [*interface_names*]
#   A hash that maps the physical interface names to their respective
#   types.  The type of interface will determine which default values
#   get applied (see: defaults parameter).  This data should be configured
#   in Hiera.  Example:
#
#     network_config::interface_names:
#       eno16780032: management
#       eno33559296: app
#
# [*defaults*]
#   A hash that provides default values to configure against a particuar
#   interface type.  This data should be configured in Hiera, example:
#
#     network_config::defaults:
#       management:
#         onboot: yes
#         dns1: 10.0.0.4
#         dns2: 10.0.0.2
#         gateway: 10.0.1.1
#         zone: restricted
#      app:
#        onboot: yes
#        dns1: 10.2.1.2
#        dns1: 10.2.1.3
#        gateway: 10.2.1.1
#        zone: trusted
#        defroute: yes
#
# [*ifconfig*]
#   A hash that contains per-host specific interface configuration,
#   normally just IP address and netmask but any configurable option
#   may be specified here and will be used to override any default
#   that exists in the defaults hash.  Normally this would be configured
#   at the highest level (certname) in Hiera, example:
#
#     network_config::ifconfig:
#       management:
#         ipaddr: 10.0.1.22
#         netmask: 255.255.248.0
#       app:
#         ipaddr: 10.2.1.44
#         netmask: 255.255.255.0
#
# [*exclude_if*]
#   Specify interfaces to be ignored, by default, lo
#
# === Configurable flags
#
# Currently the following settings can be managed in either the ifconfig
# or defaults hash:
#
#    netmask
#    bootproto
#    defroute
#    ipv4_failure_fatal
#    ipv6init
#    ipv6_autoconf
#    ipv6_defroute
#    ipv6_failure_fatal
#    uuid
#    onboot
#    dns1
#    dns2
#    domain
#    hwaddr
#    ipaddr
#    prefix
#    gateway
#    ipv6_peerdns
#    ipv6_peerroutes
#    zone
#    interface_type
#
# New flags can be added by specifying them in network_config::ifconfig
#
#
# === Examples
#
#  class { network_config:
#  }
#
# === Authors
#
# Craig Dunn <craig@craigdunn.org>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class network_config (
  $interfaces = $::interfaces,
  $interface_names,
  $defaults,
  $ifconfig,
  $vlans,
  $exclude_if = 'lo',
  $networkmanager = $::network_config::params::networkmanager,
  $restart_service = true,
  $restart_interface = false,
  $bonds = {}
) inherits network_config::params {

  # In this base class we pull in the data from hiera, which
  # will get referenced here from the interface definition below.

  if $restart_interface and $restart_service {
    fail('Only one of restart_interface or restart_service can be enabled')
  }

  service { 'network':
    ensure => running,
  }


  # Create an array of configured interfaces, minus any to be excluded
  # and then for each interface we declare a network_config::interface
  # type to instantiate the setup for that interface using the data
  # we've already loaded into the params of this class.
  #
  $int_a = split($interfaces,',')
  $parsed_ints = delete($int_a, $exclude_if)

  $bond_names = keys($bonds)
  network_config::interface { $bond_names: }
  network_config::interface { $parsed_ints: }

}





