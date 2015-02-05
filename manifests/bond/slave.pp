define network_config::bond::slave (
  $master,
)
 {

  network_config::ifconfig { "${title}-slave":
    interface_type   => 'Ethernet',
    onboot           => 'yes',
    device           => $title,
    slave            => "yes",
    master           => $master,
  }
}

    
      
