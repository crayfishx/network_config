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
# Craig Dunn <cdunn@redhat.com>
#
# 
define network_config::interface  (
) {

  # Determine what type of interface we are configuring (eg: management)
  $int_type = $::network_config::interface_names[$title]

  # Look up the default values for this interface type
  # and also add the 'target' parameter to the hash
  $int_defaults = merge($::network_config::defaults[$int_type], {})





  # Look up the override paramters for this host (ipaddress..etc)
  $int_params = merge($::network_config::ifconfig[$int_type], {})

  $vlan = $::network_config::vlans[$int_params['vlan']]
  $params_merged = merge($vlan, $int_params)


  # Build the resource hash, consisting of the interface id and parameters
  $resource = { "${title}" => $params_merged }

  # Pass the resource and defaults hash to create_resources to declare
  # a network_config::ifconfig resource to manage the individual parts
  # of the sysconfig file.
  if ( $int_type ) {
    create_resources('network_config::ifconfig', $resource , $int_defaults)
  }

}


