define network_config::ifconfig::setting (
  $target,
  $setting = false,
  $value,
) { 


  if ( $setting ) {
    $real_setting = $setting
  } else {
    $real_setting = inline_template('<%= @title.split(/:/)[1].to_s.upcase %>')
  }

  if ( $value ) {
 notify { "${title} setting $real_setting to $value in $target": }
    ini_setting { "network_config::ifconfig::${target}${title}":
      path              => $target,
      ensure            => present,
      section           => '',
      key_val_separator => '=',
      setting           => $real_setting,
      value             => $value,
    }
  }
}

