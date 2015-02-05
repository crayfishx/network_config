define network_config::bond (
  $interfaces,
) {

  network_config::bond::slave { $interfaces:
    master => $title,
  }

  network_config::interface { $title: }


}

