# == Define: network_config::ifconfig
#
# This definition manages individual configurable parameters
# in a RHEL interface specification file.  It should be considered
# "private" and only implemented by the network_config::interface
# type.
#
# === Authors
#
# Craig Dunn <craig@craigdunn.org>
#
# 
define network_config::ifconfig (
  $device=$title,
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
  $networkmanager=$::network_config::networkmanager,
  $peerdns=undef,
) {


  if $ipaddr {
    if $networkmanager {
      $ip_allocations = any2array($ipaddr)
    } else {
      $ip_allocations = $ipaddr
    }
    Ip_allocation {
      ensure    => present,
      prefix    => $prefix,
      gateway   => $gateway,
      interface => $interface_name,
    }
    ip_allocation { $ip_allocations: }
  }

  network_interface { $title:
    netmask            => $netmask,
    bootproto          => $bootproto,
    defroute           => $defroute,
    ipv4_failure_fatal => $ipv4_failure_fatal,
    ipv6init           => $ipv6init,
    ipv6_autoconf      => $ipv6_autoconf,
    ipv6_defroute      => $ipv6_defroute,
    ipv6_failure_fatal => $ipv6_failure_fatal,
    uuid               => $uuid,
    onboot             => $onboot,
    dns1               => $dns1,
    dns2               => $dns2,
    domain             => $domain,
    hwaddr             => $hwaddr,
    ipv6_peerdns       => $ipv6_peerdns,
    ipv6_peerroutes    => $ipv6_peerroutes,
    zone               => $zone,
    type               => $interface_type,
    device             => $device,
    bonding_opts       => $bonding_opts,
    bonding_master     => $bonding_master,
    master             => $master,
    slave              => $slave,
    peerdns            => $peerdns,
  }



}

