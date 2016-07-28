require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:nm_create_ip, :type => :statement, :doc => <<-'ENDDOC'

This function takes an array of IP addresses and creates Network_config::Ifconfig::Setting
resources in the form of IPADDR0, IPADDR1...etc for NetworkManager

ENDDOC

) do | args |

  ipaddresses, prefix, gateway, setting, rtitle, defaults = args
  ips=[ipaddresses].flatten
  resources = {}
  counter=-1
  Puppet::Parser::Functions.function(:create_resources)

  ips.each do |i|
    resource = { "#{rtitle}:#{setting}#{counter+=1}" => {
                   "value"   => i
                   },
                 "#{rtitle}:PREFIX#{counter}" => {
                   "value"   => prefix,
                 },
                 "#{rtitle}:GATEWAY#{counter}" => {
                   "value"   => gateway,
                 }
               }

    function_create_resources( ['Network_config::Ifconfig::Setting', resource, defaults])
  end
end


  
  
  
