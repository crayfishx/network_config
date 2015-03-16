define network_config::ifconfig::setting (
  $ensure = 'present',
  $target,
  $setting = false,
  $value = undef,
) { 


  if ( $setting ) {
    $real_setting = $setting
  } else {
    $real_setting = inline_template('<%= @title.split(/:/)[1].to_s.upcase %>')
  }

  if ( $value or $ensure == 'absent' ) {
    ini_setting { "network_config::ifconfig::${target}${title}":
      path              => $target,
      ensure            => $ensure,
      section           => '',
      key_val_separator => '=',
      setting           => $real_setting,
      value             => $value,
    }
  }
}

