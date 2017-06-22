require 'spec_helper'

default_provider =  Puppet::Type.type(:ip_route).provider(:default)

describe default_provider, fakefs: true  do

  before(:each) { 
    stub_sysconfig 
  }

  let(:providers) do
    resource_types = {}
    [
      Puppet::Type.type(:ip_route).new(
        :title     => '10.1.2.0/24',
        :gateway   => '10.1.2.8',
        :interface => 'eth99',
      ),
      Puppet::Type.type(:ip_route).new(
        :title     => '10.72.10.0',
        :gateway   => '10.72.10.1',
        :netmask   => '255.255.254.0',
        :interface => 'eth99',
      ),
      Puppet::Type.type(:ip_route).new(
        :title     => '8.9.10.0/24',
        :gateway   => '8.9.10.1',
        :interface => 'eth99',
      )
    ].each do |resource|
    resource_types[resource.name] = resource
    end
    described_class.prefetch(resource_types)
    resource_types
  end


  context "when exists" do
    it "should exist when using CIDR titles" do
      provider = providers["10.1.2.0"].provider
      expect(provider.exists?).to eq(true)
    end
    
    it "should exist when using netmask" do
      provider = providers["10.72.10.0"].provider
      expect(provider.exists?).to eq(true)
    end
  end

  context "when adding a new entry" do

    before do
      provider.create
      provider.flush
    end

    let(:provider) { providers["8.9.10.0"].provider }

    it "should not exist" do
      expect(provider.exists?).to eq(false)
    end

    it "should create a new entry" do
      settings=File.read("/etc/sysconfig/network-scripts/route-eth99").split("\n")
      expect(settings).to include( 
        'ADDRESS3=8.9.10.0',
        'NETMASK3=255.255.255.0',
        'GATEWAY3=8.9.10.1'
      )
    end

    it "should not have removed the existing ip routes" do
      settings=File.read("/etc/sysconfig/network-scripts/route-eth99").split("\n")
      expect(settings).to include(
        'ADDRESS0=10.1.2.0',
        'NETMASK0=255.255.255.0',
        'GATEWAY0=10.1.2.8',
        'ADDRESS1=10.72.10.0',
        'NETMASK1=255.255.254.0',
        'GATEWAY1=10.72.10.1',
        'ADDRESS2=192.88.0.0',
        'NETMASK2=255.255.255.0',
        'GATEWAY2=192.88.0.1'
      )
    end
  end
#
  context "when removing an entry" do
#
    before do
      provider.destroy
      provider.flush
    end

    let(:provider) { providers["10.72.10.0"].provider }
#
    it "should remove it" do
      settings=File.read("/etc/sysconfig/network-scripts/route-eth99").split("\n")
      expect(settings).not_to include('ADDRESS1=10.72.10.0')
    end
    it "should leave remaining routes with no sequence gaps" do
      settings=File.read("/etc/sysconfig/network-scripts/route-eth99").split("\n")
      expect(settings).to include(
        'ADDRESS0=10.1.2.0',
        'NETMASK0=255.255.255.0',
        'GATEWAY0=10.1.2.8',
        'ADDRESS1=192.88.0.0',
        'NETMASK1=255.255.255.0',
        'GATEWAY1=192.88.0.1'
      )
    end

  end
#
  context "when changing interfaces" do
    let(:provider) { providers["10.1.2.0"].provider }
    before do
      provider.interface=('ens39')
      provider.flush
    end

    it "should be removed from the old interface" do
      settings=File.read("/etc/sysconfig/network-scripts/route-eth99").split("\n")
      expect(settings).not_to include(/ADDRESS.=10.1.2.0/)
    end

    it "should be present in the new interface" do
      settings=File.read("/etc/sysconfig/network-scripts/route-ens39").split("\n")
      expect(settings).to include(
        'ADDRESS0=10.1.2.0',
        'NETMASK0=255.255.255.0',
        'GATEWAY0=10.1.2.8'
      )
    end

  end


end

