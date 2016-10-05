# == Define: network_config::interface
#
# This definition serves as a wrapper to network_config::ifconfig
# which actually manages the settings, here we manipulate the data
# from the base class, which is derived from hiera, to build up
# a resource model to pass to ifconfig.
#
# The title of this defined resource should be the configured name
# of the interface.
#
# === Authors
#
# Craig Dunn <craig@craigdunn.org>
#
# 
define network_config::interface  (
) {


  if !defined(Class['network_config']) {
    fail('network_config base class must be included before network_config::interface')
  }

  # Declare a service for this interface.  This enables individual
  # interfaces to be restarted upon change, rather than the whole
  # network service.
  #
  service { "ifconfig-${name}":
    ensure     => running,
    status     => "/usr/bin/grep 1 /sys/class/net/${name}/carrier",
    stop       => "/sbin/ifdown ${name}",
    start      => "/sbin/ifup ${name}",
    hasrestart => false,
    hasstatus  => false,
    provider   => 'base'
  }


  # Determine what type of interface we are configuring (eg: management)
  #
  $int_type = $::network_config::interface_names[$title]

  if (!$int_type) {
    fail("Interface ${title} not configured in interface_names")
  }

  # If we are a bond interface, add the slave patrameter
  #
  $bonds = $::network_config::bonds
  $master = inline_template('<%= @bonds.select { |b,i| i["interfaces"].include?(@name) }.keys[0] %>')


  if $master {
    $slave_config = {
      'slave'  => 'yes',
      'master' => $master
    }
  } else {
    $slave_config = {}
  }


  # Look up the default values for this interface type
  $int_defaults = $::network_config::defaults[$int_type]

  # Look up any bond specific overrides
  if $bonds[$name] {
    $master_defaults = {
      'interface_type' => 'Bond',
      'bonding_master' => 'yes'
    }
    $bond_overrides = merge($master_defaults,$::network_config::bond_defaults,delete($bonds[$name], 'interfaces'))
  } else {
    $bond_overrides = {}
  }


  # Look up the paramters for this host from network_config::ifconfig (ipaddress..etc)
  $int_params = $::network_config::ifconfig[$int_type]



  # Look up parameters from the vlan if one has been defined for this interface
  if $int_params {
    if $int_params['vlan'] {
      $vlan_overrides = $::network_config::vlans[$int_params['vlan']]
    } else {
      $vlan_overrides = {}
    }
  }

  # Set the correct service to restart
  if $::network_config::restart_service {
    $notify_resource = { 'notify' => Service['network'] }
  } elsif $::network_config::restart_interface {
    $notify_resource = { 'notify' => Service["ifconfig-${name}"] }
  } else {
    $notify_resource = {}
  }


  # Here we take all of the various configurations and merge them in the 
  # right order (right wins).  Starting with interface defaults and finally
  # ifconfig params.
  $params_merged = merge( $notify_resource,
                          $int_defaults,
                          $bond_overrides,
                          $slave_config,
                          $vlan_overrides,
                          $int_params)


  # Build the resource hash, consisting of the interface id and parameters
  $resource = { "${title}" => $params_merged }


  # Pass the resource and defaults hash to create_resources to declare
  # a network_config::ifconfig resource to manage the individual parts
  # of the sysconfig file.
  if ( $int_type ) {
    create_resources('network_config::ifconfig', $resource , $int_defaults)
  }

}


