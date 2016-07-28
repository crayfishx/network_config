require 'spec_helper'

default_provider =  Puppet::Type.type(:ip_allocation).provider(:default)

describe default_provider, fakefs: true  do

  before(:each) { 
    stub_sysconfig 
  }

  let(:providers) do
    resource_types = {}
    [
      Puppet::Type.type(:ip_allocation).new(
        :name => '192.168.4.100',
        :interface => 'ens39',
        :gateway   => '192.168.4.1',
        :prefix    => '24'
      ),
      Puppet::Type.type(:ip_allocation).new(
        :name => '192.168.5.100',
        :interface => 'ens39',
        :gateway   => '192.168.5.1',
        :prefix    => '24',
      ),
      Puppet::Type.type(:ip_allocation).new(
        :name      => '10.72.3.100',
        :ensure    => :present,
        :interface => 'ens39',
      ),
      Puppet::Type.type(:ip_allocation).new(
        :name => '10.72.2.100',
        :ensure => :absent,
      )
    ].each do |resource|
    resource_types[resource.name] = resource
    end
    described_class.prefetch(resource_types)
    resource_types
  end


  context "when exists" do
    it "should exist" do
      provider = providers["192.168.4.100"].provider
      expect(provider.exists?).to eq(true)
    end
  end

  context "when adding a new entry" do

    before do
      provider.create
      provider.flush
    end

    let(:provider) { providers["192.168.5.100"].provider }

    it "should not exist" do
      expect(provider.exists?).to eq(false)
    end

    it "should create a new entry" do
      settings=File.read("/etc/sysconfig/network-scripts/ifcfg-ens39").split("\n")
      expect(settings).to include( 
        'IPADDR1=192.168.5.100',
        'GATEWAY1=192.168.5.1',
        'PREFIX1=24'
      )
    end

    it "should not have removed the existing ip allocation" do
      settings=File.read("/etc/sysconfig/network-scripts/ifcfg-ens39").split("\n")
      expect(settings).to include(
        'IPADDR=192.168.4.100',
        'PREFIX=24',
        'GATEWAY=192.168.4.1'
      )
    end
  end

  context "when removing an entry" do

    before do
      provider.destroy
      provider.flush
    end

    let(:provider) { providers["10.72.2.100"].provider }

    it "should remove it" do
      settings=File.read("/etc/sysconfig/network-scripts/ifcfg-eth99").split("\n")
      expect(settings).not_to include('IPADDR3=10.72.2.100')
    end
    it "should leave remaining allocations with no sequence gaps" do
      settings=File.read("/etc/sysconfig/network-scripts/ifcfg-eth99").split("\n")
      expect(settings).to include(
        'IPADDR=192.168.9.100',
        'PREFIX=24',
        'GATEWAY=192.168.9.1',
        'IPADDR1=10.72.0.100',
        'GATEWAY1=10.72.0.1',
        'PREFIX1=24',
        'IPADDR2=10.72.1.100',
        'GATEWAY2=10.72.1.1',
        'PREFIX2=24',
        'IPADDR3=10.72.3.100',
        'GATEWAY3=10.72.3.1',
        'PREFIX3=24',
      )
    end

  end

  context "when changing interfaces" do
    let(:provider) { providers["10.72.3.100"].provider }
    before do
      provider.interface=('ens39')
      provider.flush
    end

    it "should be removed from the old interface" do
      settings=File.read("/etc/sysconfig/network-scripts/ifcfg-eth99").split("\n")
      expect(settings).not_to include('IPADDR4=10.72.3.100')
    end

    it "should be present in the new interface" do
      settings=File.read("/etc/sysconfig/network-scripts/ifcfg-ens39").split("\n")
      expect(settings).to include('IPADDR1=10.72.3.100')
    end

  end


end

