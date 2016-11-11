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
      :peerdns,
    ].each do |prop|

      it "should have a #{prop} property" do
        expect(described_class.attrtype(prop)).to eq(:property)
      end
    end

    it "should have a target param" do
      expect(described_class.attrtype(:target)).to eq(:param)
    end
  end



end

