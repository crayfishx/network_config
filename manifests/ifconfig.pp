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
  $target,
  $ipaddress=undef,
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
  $zone=undef
) {

  # The behaviour of ini_setting means that any value passed in as <<undef>> will
  # be ignored and won't be managed, so we don't have to wrap everything in 
  # conditionals.  It will however create a blank entry for anything defined as
  # undef that isn't already in the sysconfig file, this is considered safe behaviour(?)


  Ini_setting {
    path              => $target,
    ensure            => present,
    section           => '',
    key_val_separator => '=',
  }

  ini_setting {
    "${title} netmask":
      setting => 'NETMASK0',
      value => $netmask;

    "${title} bootproto":
      setting => 'BOOTPROTO',
      value => $bootproto;

    "${title} defroute":
      setting => 'DEFROUTE',
      value => $defroute;

    "${title} ipv4_failure_fatal":
      setting => 'IPV4_FAILURE_FATAL',
      value => $ipv4_failure_fatal;

    "${title} ipv6init":
      setting => 'IPV6INIT',
      value => $ipv6init;

    "${title} ipv6_autoconf":
      setting => 'IPV6_AUTOCONF',
      value => $ipv6_autoconf;

    "${title} ipv6_defroute":
      setting => 'IPV6_DEFROUTE',
      value => $ipv6_defroute;

    "${title} ipv6_failure_fatal":
      setting => 'IPV6_FAILURE_FATAL',
      value => $ipv6_failure_fatal;

    "${title} uuid":
      setting => 'UUID',
      value => $uuid;

    "${title} onboot":
      setting => 'ONBOOT',
      value => $onboot;

    "${title} dns1":
      setting => 'DNS1',
      value => $dns1;

    "${title} dns2":
      setting => 'DNS2',
      value => $dns2;

    "${title} domain":
      setting => 'DOMAIN',
      value => $domain;

    "${title} hwaddr":
      setting => 'HWADDR',
      value => $hwaddr;

    "${title} ipaddr":
      setting => 'IPADDR0',
      value => $ipaddr;

    "${title} prefix":
      setting => 'PREFIX0',
      value => $prefix;

    "${title} gateway":
      setting => 'GATEWAY0',
      value => $gateway;

    "${title} ipv6_peerdns":
      setting => 'IPV6_PEERDNS',
      value => $ipv6_peerdns;

    "${title} ipv6_peerroutes":
      setting => 'IPV6_PEERROUTES',
      value => $ipv6_peerroutes;

    "${title} zone":
      setting => 'ZONE',
      value => $zone;

    "${title} int_name":
      setting => 'NAME',
      value => $int_name;

    "${title} type":
      setting => 'TYPE',
      value => $type;
    }

}
  
