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
  String           $device = $title,
  Optional[String] $interface_type=undef,
  Boolean          $nm_controlled=true,
  Optional[String] $netmask=undef,
  Optional[String] $bootproto=undef,
  Optional[String] $defroute=undef,
  Optional[String] $ipv4_failure_fatal=undef,
  Optional[String] $ipv6init=undef,
  Optional[String] $ipv6_autoconf=undef,
  Optional[String] $ipv6_defroute=undef,
  Optional[String] $ipv6_failure_fatal=undef,
  Optional[String] $uuid=undef,
  Optional[String] $onboot=undef,
  Optional[String] $dns1=undef,
  Optional[String] $dns2=undef,
  Optional[String] $dns3=undef,
  Optional[String] $domain=undef,
  Optional[String] $hwaddr=undef,
  Variant[String, Array, Undef] $ipaddr=undef,
  Optional[Integer] $prefix=undef,
  Optional[String] $gateway=undef,
  Optional[String] $ipv6_peerdns=undef,
  Optional[String] $ipv6_peerroutes=undef,
  Optional[String] $zone=undef,
  Optional[Integer] $vlan=undef,
  String           $interface_name=$title,
  Optional[String] $bonding_opts=undef,
  Optional[String] $bonding_master=undef,
  Optional[String] $slave=undef,
  Optional[String] $master=undef,
  Boolean          $networkmanager=$::network_config::networkmanager,
  Optional[String] $peerdns=undef,
  Hash             $routes={}
) {


  $routes.each | String $dest, Hash[Enum['gateway','netmask','address'], String] $rparams | {

    $route_defaults = {
      'interface' => $interface_name,
      'gateway'   => $gateway,
    }

    ip_route { $dest:
      *       => $route_defaults + $rparams,
      require => Network_interface[$interface_name],
    }
  }


  if $ipaddr {
    if $networkmanager {
      $ip_allocations = any2array($ipaddr)
      $int_gateway = undef
    } else {
      $ip_allocations = $ipaddr
      $int_gateway = $gateway
    }
      Ip_allocation {
        ensure    => present,
        prefix    => $prefix,
        gateway   => $gateway,
        interface => $interface_name,
      }
    ip_allocation { $ip_allocations: }
  } else {
    $int_gateway = $gateway
  }

  network_interface { $title:
    netmask            => $netmask,
    bootproto          => $bootproto,
    defroute           => $defroute,
    nm_controlled      => $nm_controlled,
    ipv4_failure_fatal => $ipv4_failure_fatal,
    ipv6init           => $ipv6init,
    ipv6_autoconf      => $ipv6_autoconf,
    ipv6_defroute      => $ipv6_defroute,
    ipv6_failure_fatal => $ipv6_failure_fatal,
    uuid               => $uuid,
    onboot             => $onboot,
    dns1               => $dns1,
    dns2	             => $dns2,
    dns3	             => $dns3,
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
    gateway            => $int_gateway,
  }
}

