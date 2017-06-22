require File.join(File.dirname(__FILE__), '..', 'network_config.rb')

Puppet::Type.type(:ip_route).provide(
  :default, :parent => Puppet::Provider::Network_config
) do

  desc <<-EOD
  Default provider for configuring IP routes in ifcfg files
  EOD


  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.fields
    [ :address, :netmask, :gateway ]
  end


  def create
    @property_flush = {
      :ensure      => :present,
      :address     => @resource[:address],
      :interface   => @resource[:interface],
      :gateway     => @resource[:gateway],
      :netmask     => @resource[:netmask],
      :position    => next_position
    }
  end

  def self.ifconfig(interface)
    open_config_file( 'route', interface )
  end

  def ifconfig
    @ifconfig ||= self.class.ifconfig(interface)
  end

  def netmask
    @property_flush[:netmask] || @property_hash[:netmask]
  end

  def address
    @property_flush[:address] || @property_hash[:address]
  end

  def address=(value)
    @property_flush[:address] = value
  end

  def interface
    @property_hash[:interface] || @resource[:interface]
  end

  def interface=(value)
    @property_flush[:interface] = value
  end

  def gateway=(value)
    @property_flush[:gateway] = value
  end

  def netmask=(value)
    @property_flush[:netmask] = value
  end

  def self.instances
    instances = []
    interfaces do |provider, intcfg|
      next unless provider.has_routes?
      config_sets(ifconfig(provider.device)) do |result|
        result[:name] = result[:address]
        result[:interface] = provider.device
        result[:ensure] = :present
        instances << new(result)
      end
    end
    instances
  end
      
end
