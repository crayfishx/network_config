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

  # If we are a bond interface, add the slave parameter
  #
  $bonds = $::network_config::bonds
  $master = $bonds.map | $b, $v| {
    $v['interfaces'].member($name) ? {
      true   => $b,
      false => undef,
    }
  }.flatten.delete_undef_values[0]

  if $master {
    $slave_config = {
      'slave'  => 'yes',
      'master' => $master
    }
  } else {
    $slave_config = {}
  }

  # if we are a team interface, add the devicetype and team_master parameter
  #
  $teams = $::network_config::teams
  $team_master = $teams.map |$team_name, $team_conf| {
    $team_conf['interfaces'].has_key($name) ? {
      true  => $team_name,
      false => undef,
    }
  }.flatten.delete_undef_values[0]

  if $team_master {
    $team_port_config = {
      'devicetype'  => 'TeamPort',
      'team_master' => $team_master,
    }.merge($teams[$team_master]['interfaces'][$name])
  } else {
    $team_port_config = {}
  }

  # Look up the default values for this interface type
  $int_defaults = $::network_config::defaults[$int_type]

  # Look up any bond specific overrides
  if $bonds[$name] {
    $master_defaults = {
      'interface_type' => 'Bond',
      'bonding_master' => 'yes',
    }
    $bond_overrides = merge($master_defaults,
                            $::network_config::bond_defaults,
                            delete($bonds[$name], 'interfaces'))
  } else {
    $bond_overrides = {}
  }

  # Look up any team specific overrides
  if $teams[$name] {
    $team_master_defaults = {
      'devicetype' => 'Team',
    }
    $team_overrides = merge($team_master_defaults,
                            $::network_config::team_defaults,
                            delete($teams[$name], 'interfaces'))
  } else {
    $team_overrides = {}
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
  } else {
    $vlan_overrides = {}
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
                          $team_overrides,
                          $team_port_config,
                          $vlan_overrides,
                          $int_params)

  # Build the resource hash, consisting of the interface id and parameters
  $resource = { "${title}" => $params_merged }


  # Pass the resource and defaults hash to iterator to declare
  # a network_config::ifconfig resource to manage the individual parts
  # of the sysconfig file.
  if ( $int_type ) {
    $resource.each | $resource_name, $data | {
      network_config::ifconfig { $resource_name:
        * => { before => Service["ifconfig-${name}"] } + $int_defaults + $data
      }
    }
  }

}
