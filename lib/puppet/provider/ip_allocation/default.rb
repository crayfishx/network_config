require 'puppet/util/ini_file'
require File.join(File.dirname(__FILE__), '..', 'network_config.rb')

Puppet::Type.type(:ip_allocation).provide(
  :default, :parent => Puppet::Provider::Network_config
) do

  desc <<-EOD
  IP allocation 
  EOD

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    @property_flush = {
      :ensure    => :present,
      :ipaddr    => @resource[:ipaddr],
      :name      => @resource[:ipaddr],
      :gateway   => @resource[:gateway],
      :prefix    => @resource[:prefix],
      :netmask   => @resource[:netmask],
      :interface => @resource[:interface],
      :position  => next_position
    }
  end


  def netmask=(value) 
    @property_flush[:netmask] = value
  end


  def gateway=(value) 
    @property_flush[:gateway] = value
  end

  def ipaddr
    @property_flush[:ipaddr] || @property_hash[:ipaddr]
  end

  def ipaddr=(value) 
    @property_flush[:ipaddr] = value
  end

  def prefix=(value) 
    @property_flush[:prefix] = value
  end

  def interface
    @property_hash[:interface] || @resource[:interface]
  end

  def interface=(value)
    @property_flush[:interface] = value
  end


  def self.fields
    [ :ipaddr, :netmask, :gateway, :prefix ]
  end

  def ifconfig
    @ifconfig ||= self.class.open_config_file( 'ifcfg', interface)
  end

  # Loop through all the instances of IPADDR* in the interface file and yield
  # the corresponding ip allocation set (IPADDR, NETMASK, GATEWAY...etc)
  #
  #
  def self.ip_allocations(intconfig)
    config_sets(intconfig) do |alloc|
      yield alloc
    end
  end

 def self.instances
    instances = []
    interfaces do |provider, intcfg|
      ip_allocations(intcfg) do |result|
        result[:name]=result[:ipaddr]
        result[:interface]=provider.device
        result[:ensure] = :present
        instances << new(result)
      end
    end
    instances
  end
end

