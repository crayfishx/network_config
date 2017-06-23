require 'ipaddr'

Puppet::Type.newtype(:ip_route) do

  # ip_route { '192.168.2.0/24':
  #   interface => 'eth1',
  #   gateway => '192.168.0.1',
  # }

  ensurable

  def self.cidr_to_nm(cidr)
    IPAddr.new('255.255.255.255').mask(cidr).to_s
  end

  def self.title_patterns
      [
        [ /(^([^\/]*)$)/m,
          [ [:address] ] ],
        [ /^([^\/]+)\/([^\/]+)$/,
          [ [:address], [:netmask, lambda {|c| cidr_to_nm c } ] ]
        ]
      ]
  end


  newparam(:address) do
    isnamevar
  end
  newproperty(:interface)
  newproperty(:netmask) do
    isnamevar
  end
  newproperty(:gateway)
  newparam(:position)
  newparam(:target)

  autorequire(:network_interface) do
    self[:interface]
  end
  
end

  

