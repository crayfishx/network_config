Puppet::Type.newtype(:ip_allocation) do

  ensurable

  newparam(:ipaddr) do
    isnamevar
  end
  newproperty(:interface)
  newproperty(:gateway)
  newproperty(:prefix)
  newproperty(:netmask)
  newparam(:position)

  autorequire(:network_interface) do
    self[:interface]
  end
  
end

  

