class Puppet::Provider::Network_config < Puppet::Provider

  Puppet::Type.type(:ip_allocation)
  Puppet::Type.type(:ip_route)

  # Force loading of the ini_setting type so Puppet loads the provider
  # which requires the puppet/util/ini_file library from the right place
  # We cannot do this using require because it's not guaranteed that the
  # library might not be in some other directory in the modulepath
  #
  Puppet::Type.type(:ini_setting).new(:name => '_network_config_internal')



  CONF_DIR = "/etc/sysconfig/network-scripts"

  def destroy
    @property_flush[:ensure] = :absent
  end


  def load_file_data(file)
    self.class.load_file_data(file)
  end

  def self.load_file_data(file)
    Puppet::Util::IniFile.new(file)
  end

  def self.ifcfg_files
    files = Dir.glob(File.join(CONF_DIR, "ifcfg-*"))
    files.reject{|file| file.end_with?('.bak')}
  end

  def self.conf_dir
    CONF_DIR
  end


  def self.open_config_file(prefix, name)
    file = File.join(conf_dir, "#{prefix}-#{name}")
    unless File.exists?(file)
      File.open(file, "w") {}
    end
    Puppet::Util::IniFile.new(file, '=')
  end

  def conf_dir
    @conf_dir ||= self.class.conf_dir
    @conf_dir
  end

  def exists?
    @property_hash[:ensure] == :present
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
        save_allocation(cur_position, @property_hash.merge(:ensure => :absent))
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

    save_allocation(cur_position)
    sort_positions if @property_flush[:ensure] == :absent
  end

  # save_allocation
  # Take a hash of values and save them to the network-scripts INI file for
  # the interface
  #
  def save_allocation(pos=next_position, ipalloc=@property_flush)
    fields.each do |field|
      ifconfig_param = "#{field.to_s.upcase}#{pos}"
      if ipalloc[:ensure] == :absent
        ifconfig.remove_setting('', ifconfig_param)
      else
        ifconfig.set_value('', ifconfig_param, ipalloc[field]) if ipalloc[field]
      end
    end
    ifconfig.save
  end

  def fields
    self.class.fields
  end

  def self.field_keys
    fields.map { |f| f.to_s.upcase }
  end

  def field_keys
    self.class.field_keys
  end

  def get_cur_element
    self.public_send(fields[0].to_s)
  end

  def self.index_key
    return field_keys[0]
  end

  def index_key
    self.class.index_key
  end

  # get the current position of the configuration set.  We can't rely on
  # @property_hash for this and we have to poll the file for it again as
  # we don't know if the positions have been resorted by flush since we
  # did a prefetch, however, if it exists in @property_flush then we are
  # in a create so this should be used.
  #
  def cur_position(element=get_cur_element)
    return @property_flush[:position] if @property_flush[:position]
    ifconfig.get_settings('').select {|i,v|
      i =~ /#{index_key}/ && v == element }.keys[0].gsub(/[^\d]*/,'')
  end

  # positions
  # This method returns an array of all the numerical positions for all
  # sets of configurations.  Eg: if we have IPADDR, IPADDR1, IPADDR2, IPADDR3
  # then this method will return [ 0, 1, 2, 3 ].  Note we ignore IPADDR in this
  # context
  #
  def positions
    ipkeys=ifconfig.get_settings('').keys.select {|i| i =~ /#{index_key}/ }
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
      current_alloc = self.class.match_config_set(ifconfig,p[next_pos])
      save_allocation(current_alloc[:position], current_alloc.merge(:ensure => :absent))
      save_allocation(next_pos,current_alloc)
      Puppet.debug "shifted position sequence of #{current_alloc[:ipaddr]} from  #{current_alloc[:position]} to #{next_pos}"
    end
  end



  # This method takes an inifile object as an argument and an optional argument
  # of a position (if ommited we assume there is no numerical position, eg IPADDR)
  # we return a hash of the values that match
  #
  def self.match_config_set(data, position='')
    config_set = {}
    field_keys.each do |field|
      if val = data.get_value('', "#{field}#{position}")
        config_set[field.downcase.to_sym] = val
      end
    end
    return nil if config_set.empty?
    config_set[:position] = position
    config_set
  end

  def self.config_sets(intconfig)
    index_entries = intconfig.get_settings('').keys.select { |i| i =~ /#{index_key}/ }
    index_entries.map { |i| i.gsub(/[^\d]*/,'') }.each do |ident|
      yield match_config_set(intconfig, ident)
    end
  end

  def self.prefetch(resources)
    instances.each do |p|
      if resource = resources[p.name]
        resource.provider = p
      end
    end
  end

  def self.load_file_data(file)
    Puppet::Util::IniFile.new(file, '=')
  end

  # Return provider instances of all configured interfaces
  #
  def self.interfaces
    Puppet::Type.type(:network_interface).instances.each do |int|
      file = int.provider.target
      intcfg = load_file_data(file)
      yield int.provider, intcfg
    end
  end
end
