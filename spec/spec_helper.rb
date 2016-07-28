require 'puppetlabs_spec_helper/module_spec_helper'
require 'fakefs/spec_helpers'
require 'pp'
require 'puppet'

dir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift File.join(dir, 'lib')


$:.unshift File.dirname(__FILE__) + "/fixtures/modules/inifile/lib"
require 'mocha'


module NetworkConfigSpecHelper
  extend RSpec::SharedContext
  let(:sysconfig_dir) {
    File.expand_path(
      File.join(
        File.dirname(__FILE__), 'fixtures','network-script-contents'
      )
    )
  }
 
  let(:fake_files) do
    FakeFS.deactivate!
    files = {}
    Dir.entries(sysconfig_dir).select { |s| s =~ /ifcfg-/ }.each do |file|
      files[file] = File.read(File.join(sysconfig_dir, file))
    end
    FakeFS.activate!
    files
  end
 
  def stub_sysconfig
    FakeFS.activate!
    FileUtils.rm_rf("/etc/sysconfig/network-scripts")
    FileUtils.mkdir_p("/etc/sysconfig/network-scripts")
    fake_files.each do |file, content|
      File.open("/etc/sysconfig/network-scripts/#{file}", "w") do |f|
        f.puts content
      end
    end
  end
end
RSpec.configure do |config|
    config.mock_with :rspec
    config.hiera_config = File.expand_path(File.join(__FILE__, '../fixtures/hiera.yaml'))
    config.include FakeFS::SpecHelpers, fakefs: true
    config.include NetworkConfigSpecHelper
end


