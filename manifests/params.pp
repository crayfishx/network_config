# Parameters for network_config
#
class network_config::params {

  case $::osfamily {
    'redhat': {
      $networkmanager = $::operatingsystemmajrelease ? {
        '6' => false,
        '7' => true,
        default => false,
      }
    }
    default: {
      fail("This module is not supported on ${::osfamily}")
    }
  }

}

