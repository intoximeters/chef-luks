require 'chefspec'
require_relative 'spec_helper'

describe 'luks::default' do
  let(:chef_run) { ChefSpec::Runner.new do |node|
    node.automatic[:hostname] = 'localhost'
  end.converge(described_recipe) }

  it 'should install appropriate packages' do
    expect(chef_run).to install_package('dmsetup')
    expect(chef_run).to install_package('cryptsetup')
  end
end
