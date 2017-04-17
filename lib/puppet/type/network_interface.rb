Puppet::Type.newtype(:network_interface) do


  ensurable

  newparam(:name, :namevar => true) do
    "Interface namee"
  end

  newparam(:target)

newproperty(:netmask )
newproperty(:bootproto )
newproperty(:defroute )
newproperty(:ipv4_failure_fatal)
newproperty(:ipv6init)
newproperty(:ipv6_autoconf)
newproperty(:ipv6_defroute)
newproperty(:ipv6_failure_fatal)
newproperty(:uuid)
newproperty(:onboot)
newproperty(:dns1)
newproperty(:dns2)
newproperty(:domain)
newproperty(:hwaddr)
newproperty(:ipv6_peerdns)
newproperty(:ipv6_peerroutes)
newproperty(:zone)
newproperty(:type)
newproperty(:device)
newproperty(:bonding_opts)
newproperty(:bonding_master)
newproperty(:master)
newproperty(:slave)
newproperty(:netboot )
newproperty(:nm_controlled)
newproperty(:peerdns)
newproperty(:gateway)

end


