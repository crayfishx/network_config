require File.join(File.dirname(__FILE__), '..', 'network_config.rb')
Puppet::Type.type(:network_interface).provide(:default, :parent => Puppet::Provider::Network_config) do

  desc <<-EOD
    Network interface provider
  EOD



  ## These fields directly translate to puppet resource params.
  FIELDS_LC  = [
    'NETMASK',
    'BOOTPROTO',
    'DEFROUTE',
    'IPV4_FAILURE_FATAL',
    'IPV6INIT',
    'IPV6_AUTOCONF',
    'IPV6_DEFROUTE',
    'IPV6_FAILURE_FATAL',
    'UUID',
    'ONBOOT',
    'DNS1',
    'DNS2',
    'DOMAIN',
    'HWADDR',
    'IPV6_PEERDNS',
    'IPV6_PEERROUTES',
    'ZONE',
    'TYPE',
    'DEVICE',
    'BONDING_OPTS',
    'BONDING_MASTER',
    'MASTER',
    'SLAVE',
    'NETBOOT',
    'NM_CONTROLLED',
    'NAME',
    'PEERDNS',
    'GATEWAY'
  ]

  FIELDS = FIELDS_LC
    
  mk_resource_methods

  FIELDS.each do |f|
    define_method(f.downcase + "=") do |val|
      @property_flush[f.downcase.to_sym] = val
    end
  end


  def initialize(value={})
    super(value)
    @property_flush={}
  end

  def exists?
    @property_hash[:ensure] == :present
  end
   
  def create
    @property_flush[:ensure] = :present
    FIELDS.each do |f|
      param=setting_to_param(f)
      @property_flush[param] = @resource[param] if @resource[param]
    end
  end

  def destroy
    @property_flush[:ensure] == :absent
  end



  def self.setting_to_param(setting)
    return setting.downcase.to_sym if FIELDS.include?(setting)
  end

  def setting_to_param(setting)
    self.class.setting_to_param(setting)
  end

  def flush
    if @resource[:ensure] == :absent
      filename = target
      File.delete(filename) if File.exists?(filename)
    else
      FIELDS.each do |f|
        if value = @property_flush[setting_to_param(f)]
          ifconfig.set_value('', f, value)
        end
      end
      ifconfig.save
    end
  end


  def self.instances
    instances = []
    ifcfg_files.each do |file|
      data = load_file_data(file)
      attrs = { 
        :target => file,
        :ensure => :present, 
      }
      FIELDS.each do |field|
        if val = data.get_value('',field)
          attrs[setting_to_param(field)]=val.gsub(/\"/,'')
        end
      end

      if attrs[:name]
        instances << new(attrs)
      else
        self.debug("No name found in #{file}, skipping this interface")
      end
    end
    instances
  end

  def self.prefetch(resources)
    instances.each do |p|
      if resource = resources[p.name]
        resource.provider = p
      end
    end
  end

  def ifconfig
    @ifconfig ||= self.class.open_config_file('ifcfg', resource.name)
  end

  def routes_file
    File.join(conf_dir, "route-#{resource.name}")
  end

  def has_routes?
    File.exists?(routes_file)
  end

end
