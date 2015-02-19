define network_config::bond::slave (
  $master,
)
 {


  Network_config::Ifconfig {
    interface_type => 'Ethernet',
    onboot         => 'yes',
    slave          => 'yes',
    master         => $master,
  }

  
    

  case $::operatingsystemmajrelease {
    '7': {
      network_config::ifconfig { "${title}-slave":
        device => $title,
      }
    }
    '6': {
      network_config::ifconfig { "${title}-slave":
        device         => $title,
        interface_name => $title,
      }
    }
   default: { fail ("Unsupported OS major release ${::operatingsystemmajrelease}") }
  }
 
}

    
      
