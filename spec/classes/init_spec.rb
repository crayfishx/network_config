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
      :dns3	       => "10.0.0.4",
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
      :dns3	       => "10.0.6.4",
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

  context "Routing" do
    it {
      is_expected.to contain_ip_route('10.1.1.0/24').with(
        :netmask => '255.255.255.0',
        :gateway => '10.1.1.1',
        :interface => 'ens99'
      )
      is_expected.to contain_ip_route('10.1.2.0/24').with(
        :netmask => '255.255.255.0',
        :gateway => '10.7.6.3',
        :interface => 'ens39'
      )
    }
  end

  context "When specifying multiple IP addresses" do
    it "should contain individual ip allocations on the same vlan" do
      [ '10.0.0.1', '10.0.0.2', '10.0.0.3' ]. each do |ip|
        is_expected.to contain_ip_allocation(ip).with(
          :prefix => "24",
          :gateway => "10.7.6.3",
          :interface => "ens80",
        )
      end
    end
  end

  context "When specifying restart_service" do
    let(:params) {{
      :restart_service => true,
      :restart_interface => false,
    }}

    it  "should have network_interfaces notifying the network service" do
      [ 'ens39', 'ens99', 'ens51', 'ens52' ].each do |int|
        is_expected.to contain_network_interface(int).that_notifies('Service[network]')
        is_expected.not_to contain_network_interface(int).that_notifies("Service[ifconfig-#{int}]")
      end
    end

    it "should have ip_allocations notifying the network service" do
      [ '10.9.1.10', '10.7.6.10', '10.1.1.1' ].each do |ip|
        is_expected.to contain_ip_allocation(ip).that_notifies('Service[network]')
      end
    end

  end

  context "When specifying restart_interface" do
    let(:params) {{
      :restart_service => false,
      :restart_interface => true,
    }}
    it "should have network_interfaces notifying the interface service" do
      [ 'ens39', 'ens99', 'ens51', 'ens52' ].each do |int|
        is_expected.not_to contain_network_interface(int).that_notifies('Service[network]')
        is_expected.to contain_network_interface(int).that_notifies("Service[ifconfig-#{int}]")
      end
    end

    it "should have ip_allocations that notify the interface" do
      is_expected.to contain_ip_allocation('10.9.1.10').that_notifies("Service[ifconfig-ens99]")
      is_expected.to contain_ip_allocation('10.7.6.10').that_notifies("Service[ifconfig-ens39]")
      is_expected.to contain_ip_allocation('10.1.1.1').that_notifies("Service[ifconfig-bond0]")
    end

    it "should not notify the network service from ip allocations" do
      is_expected.not_to contain_ip_allocation('10.9.1.10').that_notifies("Service[network]")
      is_expected.not_to contain_ip_allocation('10.7.6.10').that_notifies("Service[network]")
      is_expected.not_to contain_ip_allocation('10.1.1.1').that_notifies("Service[network]")
    end

  end


  context "When specifying no restarts" do
    let(:params) {{
      :restart_service => false,
      :restart_interface => false,
    }}
    it "should have network_interfaces notifying the interface service" do
      [ 'ens39', 'ens99', 'ens51', 'ens52' ].each do |int|
        is_expected.not_to contain_network_interface(int).that_notifies('Service[network]')
        is_expected.not_to contain_network_interface(int).that_notifies("Service[ifconfig-#{int}]")
      end
    end

    it "should have ip_allocations that notify the interface" do
      is_expected.not_to contain_ip_allocation('10.9.1.10').that_notifies("Service[ifconfig-ens99]")
      is_expected.not_to contain_ip_allocation('10.7.6.10').that_notifies("Service[ifconfig-ens39]")
      is_expected.not_to contain_ip_allocation('10.1.1.1').that_notifies("Service[ifconfig-bond0]")
    end

    it "should not notify the network service from ip allocations" do
      is_expected.not_to contain_ip_allocation('10.9.1.10').that_notifies("Service[network]")
      is_expected.not_to contain_ip_allocation('10.7.6.10').that_notifies("Service[network]")
      is_expected.not_to contain_ip_allocation('10.1.1.1').that_notifies("Service[network]")
    end

  end


  context 'When specifying teaming' do
    it 'should contain team_config hash converted to a json string' do
      str = '{"runner":{"name":"lacp","active":true,"fast_rate":true},"link_watch":{"name":"ethtool"}}'
      is_expected.to contain_network_interface('team0').with_team_config(str)
    end
    it 'should set the correct devicetype' do
      is_expected.to contain_network_interface('team0').with_devicetype('Team')
      is_expected.to contain_network_interface('ens61').with_devicetype('TeamPort')
      is_expected.to contain_network_interface('ens62').with_devicetype('TeamPort')
    end
    it 'should set the team master' do
      is_expected.to contain_network_interface('ens61').with_team_master('team0')
      is_expected.to contain_network_interface('ens62').with_team_master('team0')
    end
    it 'should set the interface specific team_port_config settings' do
      is_expected.to     contain_network_interface('ens61').with_team_port_config('{"prio":100}')
      is_expected.to_not contain_network_interface('ens62').with_team_port_config('{"prio":100}')
    end
  end

end

