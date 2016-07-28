require 'spec_helper'
describe 'network_config' do

  let (:facts) { {
      :osfamily => 'RedHat',
      :operatingsystemmajrelease => '7'
  } }


  @ifconfig = {
    'ens39' => {
      :bootproto      => "none",
      :defroute       => "no",
      :dns1           => "10.0.0.2",
      :dns2           => "10.0.0.3",
      :domain         => "enviatics.com",
      :interface_type => "Ethernet",
      :onboot         => "yes",
      :vlan           => "100",
      :prefix         => "24",
      :ipaddr         => "10.7.6.10"
    },
    'ens99' => {
      :bootproto      => "none",
      :defroute       => "no",
      :dns1           => "10.0.6.2",
      :dns2           => "10.0.6.3",
      :domain         => "app.enviatics.com",
      :interface_type => "Ethernet",
      :onboot         => "yes",
      :vlan           => "200",
      :prefix         => "23",
      :ipaddr         => "10.9.1.10"
    }
  } 

  context 'with defaults for all parameters' do
    it { should contain_class('network_config') }
  end

  @ifconfig.each do |int, config|

    network_interface_cfg = config.reject { |k,v| [ :vlan, :prefix, :ipaddr].include?(k) }
    network_interface_cfg[:type]=network_interface_cfg.delete(:interface_type)

    context "for interface #{int}" do
      it { is_expected.to contain_network_config__interface(int) }
      it { is_expected.to contain_service("ifconfig-#{int}") }
      it { is_expected.to contain_network_config__ifconfig(int).with(config) }
      it { is_expected.to contain_network_interface(int).with(network_interface_cfg) }
    end
  end
end

