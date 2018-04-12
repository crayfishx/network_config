Puppet::Type.newtype(:network_interface) do

  ensurable

  newparam(:name, :namevar => true) do
    "Interface namee"
  end

  newparam(:target)

  # This will always put '' around the value
  ensure_singlequoted = Proc.new do
    munge do |value|
      unless value.match(/\A\'.*\'\z/)
        "\'#{value}\'"
      else
        value
      end
    end
  end

  # This will only put "" around the value if
  # required (if the value contains spaces)
  ensure_doublequoted_if_required = Proc.new do
    munge do |value|
      if value.include?(' ') && !value.match(/\A\".*\"\z/)
        "\"#{value}\""
      else
        value
      end
    end
  end

  newproperty(:netmask)
  newproperty(:bootproto)
  newproperty(:defroute)
  newproperty(:ipv4_failure_fatal)
  newproperty(:ipv6init)
  newproperty(:ipv6_autoconf)
  newproperty(:ipv6_defroute)
  newproperty(:ipv6_failure_fatal)
  newproperty(:uuid)
  newproperty(:onboot)
  newproperty(:dns1)
  newproperty(:dns2)
  newproperty(:dns3)
  newproperty(:domain, &ensure_doublequoted_if_required)
  newproperty(:hwaddr)
  newproperty(:ipv6_peerdns)
  newproperty(:ipv6_peerroutes)
  newproperty(:zone)
  newproperty(:type)
  newproperty(:device)
  newproperty(:bonding_opts, &ensure_doublequoted_if_required)
  newproperty(:bonding_master)
  newproperty(:master)
  newproperty(:slave)
  newproperty(:netboot)
  newproperty(:nm_controlled)
  newproperty(:peerdns)
  newproperty(:gateway)
  newproperty(:devicetype)
  newproperty(:team_master)
  newproperty(:team_port_config, &ensure_singlequoted)
  newproperty(:team_config, &ensure_singlequoted)

end
