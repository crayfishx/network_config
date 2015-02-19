# == Define: network_config::ifconfig
#
# This definition manages individual configurable parameters
# in a RHEL interface specification file.  It should be considered
# "private" and only implemented by the network_config::interface
# type.
#
# === Authors
#
# Craig Dunn <cdunn@redhat.com>
#
# 
define network_config::ifconfig (
  $device=$title,
  $ipaddress=undef,
  $interface_type=undef,
  $netmask=undef,
  $bootproto=undef,
  $defroute=undef,
  $ipv4_failure_fatal=undef,
  $ipv6init=undef,
  $ipv6_autoconf=undef,
  $ipv6_defroute=undef,
  $ipv6_failure_fatal=undef,
  $uuid=undef,
  $onboot=undef,
  $dns1=undef,
  $dns2=undef,
  $domain=undef,
  $hwaddr=undef,
  $ipaddr=undef,
  $prefix=undef,
  $gateway=undef,
  $ipv6_peerdns=undef,
  $ipv6_peerroutes=undef,
  $zone=undef,
  $vlan=undef,
  $interface_name=$title,
  $bonding_opts=undef,
  $bonding_master=undef,
  $slave=undef,
  $master=undef,
) {

  $target = "/etc/sysconfig/network-scripts/ifcfg-${interface_name}"

  Network_config::Ifconfig::Setting {
    target => $target,
    notify => Service['network'],
  }

  network_config::ifconfig::setting {
    "${title}:netmask":  value => $netmask;
    "${title}:bootproto":  value => $bootproto;
    "${title}:defroute":  value => $defroute;
    "${title}:ipv4_failure_fatal": value => $ipv4_failure_fatal;
    "${title}:ipv6init": value => $ipv6init;
    "${title}:ipv6_autoconf": value => $ipv6_autoconf;
    "${title}:ipv6_defroute": value => $ipv6_defroute;
    "${title}:ipv6_failure_fatal": value => $ipv6_failure_fatal;
    "${title}:uuid": value => $uuid;
    "${title}:onboot": value => $onboot;
    "${title}:dns1": value => $dns1;
    "${title}:dns2": value => $dns2;
    "${title}:domain": value => $domain;
    "${title}:hwaddr": value => $hwaddr;
    "${title}:ipaddr": value => $ipaddr;
    "${title}:prefix": value => $prefix;
    "${title}:gateway": value => $gateway;
    "${title}:ipv6_peerdns": value => $ipv6_peerdns;
    "${title}:ipv6_peerroutes": value => $ipv6_peerroutes;
    "${title}:zone": value => $zone;
    "${title}:interface_type": value => $interface_type, setting => "TYPE";
    "${title}:device": value => $device;
    "${title}:interface_name": value => $interface_name, setting => "NAME";
    "${title}:bonding_opts": value => $bonding_opts;
    "${title}:bonding_master": value => $bonding_master;
    "${title}:master": value => $master;
    "${title}:slave": value => $slave;
  }
}

