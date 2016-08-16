require 'puppet/util/ini_file'
Puppet::Type.type(:network_interface).provide(:default) do

  desc <<-EOD
    Network interface provider
  EOD

  CONF_DIR = "/etc/sysconfig/network-scripts"

  def self.conf_dir
    CONF_DIR
  end

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
    'NAME'
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
      raise Puppet::Error, "No name found in #{file}" unless attrs[:name]
      instances << new(attrs)
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
    @ifconfig ||= Puppet::Util::IniFile.new(File.join(CONF_DIR, "ifcfg-#{resource.name}"), '=')
    @ifconfig
  end

  def load_file_data(file)
    self.class.load_file_data(file)
  end

  def self.load_file_data(file)
    Puppet::Util::IniFile.new(file)
  end


  def self.ifcfg_files
    Dir.glob(File.join(CONF_DIR, "ifcfg-*"))
  end

end
