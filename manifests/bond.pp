define network_config::bond (
  $interfaces,
) {


  network_config::interface { $title: }

  kmod::alias { $title:
    modulename => 'bonding',
  }

  kmod::option {
    "${title} mode":
      module => $title,
      option => 'mode',
      value  => '1';
    "${title} miimon":
      module => $title,
      option => 'miimon',
      value  => '100';
  }



}

