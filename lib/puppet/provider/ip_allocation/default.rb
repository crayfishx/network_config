require 'puppet/util/ini_file'

Puppet::Type.type(:ip_allocation).provide(:default) do

  desc <<-EOD
  IP allocation 
  EOD

  mk_resource_methods

  def self.conf_dir
    Puppet::Type.type(:network_interface).defaultprovider.conf_dir
  end

  def conf_dir
    @conf_dir ||= self.class.conf_dir
    @conf_dir
  end

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def exists?
    @property_hash[:ensure] == :present
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


  def destroy
    @property_flush[:ensure] = :absent
  end


  def ifconfig
    file = File.join(conf_dir, "ifcfg-#{interface}")
    raise Puppet::Error, "No such interface file #{file}" unless File.exists?(file)
    @ifconfig ||= Puppet::Util::IniFile.new(file, '=')
    @ifconfig
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
#
  def interface=(value)
    @property_flush[:interface] = value
  end


  ## Flush values, we make this overridable to allow the sort_positions method
  ## to call this method
  #
  def flush

    # It's possible we've changed the interface parameter, this is a valid
    # use case so we should move the ip allocation into the correct int
    # file

    if @property_flush[:interface]
      unless @property_flush[:interface] == interface

        ## Remove the entry from the old interface file and clean up
        save_allocation(position, @property_hash.merge(:ensure => :absent))
        sort_positions

        ## Reset the interface and position with a new inifile object
        @ifconfig = nil
        @property_hash[:interface] = @property_flush[:interface]
        @property_flush[:position] = next_position

        ## Place our original resource, with any updates, into the new interface
        merged_props = @property_hash.merge(@property_flush)
        @property_flush = merged_props
        end
    end

    save_allocation(position)
    sort_positions if @property_flush[:ensure] == :absent
  end

  # save_allocation
  # Take a hash of values and save them to the network-scripts INI file for
  # the interface
  #
  def save_allocation(pos=next_position, ipalloc=@property_flush)
    [:ipaddr, :netmask, :prefix, :gateway].each do |field|
      ifconfig_param = "#{field.to_s.upcase}#{pos}"
      if ipalloc[:ensure] == :absent
        ifconfig.remove_setting('', ifconfig_param)
      else
        ifconfig.set_value('', ifconfig_param, ipalloc[field]) if ipalloc[field]
      end
    end
    ifconfig.save
  end

  def position
    position(ipaddr)
  end

  # position(ipaddr)
  # get the current position of the ip allocation set.  We can't rely on
  # @property_hash for this and we have to poll the file for it again as
  # we don't know if the positions have been resorted by flush since we 
  # did a prefetch, however, if it exists in @property_flush then we are
  # in a create so this should be used.
  #
  def position(ip=ipaddr)
    return @property_flush[:position] if @property_flush[:position]
    ifconfig.get_settings('').select {|i,v| 
      i =~ /IPADDR/ && v == ip }.keys[0].gsub(/[^\d]*/,'')
  end
    
  # positions
  # This method returns an array of all the numerical positions for all
  # sets of ip allocations.  Eg: if we have IPADDR, IPADDR1, IPADDR2, IPADDR3
  # then this method will return [ 0, 1, 2, 3 ].  Note we ignore IPADDR in this
  # context
  #
  def positions
    ipkeys=ifconfig.get_settings('').keys.select {|i| i =~ /IPADDR/ }
    ipkeys.map { |i| i.gsub(/[^\d]*/,'').to_i }.sort
  end


  # next_position
  # Provide the next available position in the sequence, even if it falls
  # within a gap.  If we have a gap in the sequence then create will automatically
  # use the first free available slot, if not, it will use the next available
  # (length+1)
  #
  def next_position
    p = positions
    return 0 if p.empty?
    ((0 .. p.last).to_a - p).first  || p.last + 1
  end

  # sort_positions
  # This method is called whenever a provider sets absent via flush.  It is important
  # to always maintain the sequence of identifiers for ip allocation sets, that is, if
  # we end up with IPADDR1, IPADDR2, IPADDR4, IPADDR5 then everything after IPADDR2 will
  # be ignored by Network Manager.  Since we don't know what other resources in the catalog
  # might remove resources and create gaps in the sequence, the safest way is just to always
  # call this method after we remove anything
  #
  def sort_positions
    until ( p = positions).length == (next_pos = next_position)
      current_alloc = self.class.match_ip_alloc_set(ifconfig,p[next_pos])
      save_allocation(current_alloc[:position], current_alloc.merge(:ensure => :absent))
      save_allocation(next_pos,current_alloc)
      Puppet.debug "shifted position sequence of #{current_alloc[:ipaddr]} from  #{current_alloc[:position]} to #{next_pos}"
    end
  end


    
  # match_ip_alloc_set
  # This method takes an inifile object as an argument and an optional argument
  # of a position (if ommited we assume there is no numerical position, eg IPADDR)
  # we return a hash of the values that match, eg:
  #   {
  #     :ipaddr   => '192.168.22.4',
  #     :prefix   => '24',
  #     :gateway  => '192.168.22.1',
  #     :position => 4
  #   }
  #
  def self.match_ip_alloc_set(data, position='')
    fields=['IPADDR','GATEWAY','PREFIX','NETMASK']
    ip_set = {}
    fields.each do |field|
      if val = data.get_value('', "#{field}#{position}")
        ip_set[field.downcase.to_sym] = val
      end
    end
    return nil if ip_set.empty?
    ip_set[:position] = position
    ip_set
  end

  # self.ip_allocations
  # Loop through all the instances of IPADDR* in the interface file and yield
  # the corresponding ip allocation set (IPADDR, NETMASK, GATEWAY...etc)
  #
  def self.ip_allocations(intconfig)
    ips = intconfig.get_settings('').keys.select { |i| i =~ /IPADDR/ }
    ips.map { |i| i.gsub(/[^\d]*/,'') }.each do |ident|
      yield match_ip_alloc_set(intconfig, ident)
    end
  end

    
  def self.prefetch(resources)
    instances.each do |p|
      if resource = resources[p.name]
        resource.provider = p
      end
    end
  end


  def self.instances
    interfaces=Puppet::Type.type(:network_interface).instances
    instances = []
    interfaces.each do |int|
      interface_name = int.provider.device
      file = int.provider.target
      intcfg = load_file_data(file)

      ip_allocations(intcfg) do |result|
        result[:name]=result[:ipaddr]
        result[:interface]=interface_name
        result[:ensure] = :present
        instances << new(result)

      end
    end
    instances
  end

  def self.load_file_data(file)
    Puppet::Util::IniFile.new(file, '=')
  end

end

