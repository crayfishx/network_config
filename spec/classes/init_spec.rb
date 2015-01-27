require 'spec_helper'
describe 'network_config' do

  context 'with defaults for all parameters' do
    it { should contain_class('network_config') }
  end
end
