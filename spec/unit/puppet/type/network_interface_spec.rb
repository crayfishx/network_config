require 'spec_helper'

describe Puppet::Type.type(:network_interface) do


  context "when validating attributes" do
    [
      :netmask,
      :bootproto,
      :defroute,
      :ipv4_failure_fatal,
      :ipv6init,
      :ipv6_autoconf,
      :ipv6_defroute,
      :ipv6_failure_fatal,
      :uuid,
      :onboot,
      :dns1,
      :dns2,
      :domain,
      :hwaddr,
      :ipv6_peerdns,
      :ipv6_peerroutes,
      :zone,
      :type,
      :device,
      :bonding_opts,
      :bonding_master,
      :master,
      :slave,
      :netboot ,
      :nm_controlled,
    ].each do |prop|

      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end

    it "should have a target param" do
      expect(described_class.attrtype(:target)).to eq(:param)
    end
  end


  describe "provider" do
   let(:provider) do
     resource = Puppet::Type.type(:network_interface).new(
       :name      => 'ens99',
       :ensure    => 'present',
       :bootproto => 'none',
       :defroute  => 'no',
       :device    => 'ens99',
       :dns1      => '10.0.6.2',
       :dns2      => '10.0.6.3',
       :domain    => 'app.enviatics.com',
       :onboot    => 'yes',
       :slave     => 'yes',
       :type      => 'Ethernet',
     )
     prov = Puppet::Type.type(:network_interface).provider(:default)
     prov.prefetch( { resource.name => resource } )
    end

   it "should exist" do
     expect(provider.exists?).to be_truthy
   end

   it "should delete the ifconfig file on purge" do
     File.expects(:delete).with("/etc/sysconfig/ifcfg-ens99")
     provider.destroy
   end

  end
    



end

