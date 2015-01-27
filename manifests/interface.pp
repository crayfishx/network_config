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
  $target = "/etc/sysconfig/network-scripts/ifcfg-${title}"
) {

  # Determine what type of interface we are configuring (eg: management)
  $int_type = $::network_config::interface_names[$title]

  # Look up the default values for this interface type
  # and also add the 'target' parameter to the hash
  $int_defaults = merge($::network_config::defaults[$int_type], { target => $target })

  # Look up the override paramters for this host (ipaddress..etc)
  $int_params = $::network_config::ifconfig[$int_type]

  # Build the resource hash, consisting of the interface id and parameters
  $resource = { "${title}" => $int_params }

  # Pass the resource and defaults hash to create_resources to declare
  # a network_config::ifconfig resource to manage the individual parts
  # of the sysconfig file.
  create_resources('network_config::ifconfig', $resource , $int_defaults)

}


