# Encoding: utf-8
require_relative 'spec_helper'

describe 'openstack-network::server' do
  describe 'suse' do
    let(:runner) { ChefSpec::Runner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set['openstack']['compute']['network']['service_type'] = 'neutron'
      runner.converge(described_recipe)
    end

    include_context 'neutron-stubs'

    it 'does not install openstack-neutron when nova networking' do
      node.override['openstack']['compute']['network']['service_type'] = 'nova'

      expect(chef_run).to_not install_package 'openstack-neutron'
    end

    it 'installs openstack-neutron packages' do
      expect(chef_run).to install_package 'openstack-neutron'
    end

    it 'enables openstack-neutron service' do
      expect(chef_run).to enable_service 'openstack-neutron'
    end

    it 'does not install openvswitch package' do
      expect(chef_run).not_to install_package 'openstack-neutron-openvswitch'
    end

    describe '/etc/sysconfig/neutron' do
      let(:file) { chef_run.template('/etc/sysconfig/neutron') }

      it 'creates /etc/sysconfig/neutron' do
        expect(chef_run).to create_template(file.name).with(
          user: 'root',
          group: 'root',
          mode: 0644
        )
      end

      it 'has the correct plugin config location - ovs by default' do
        expect(chef_run).to render_file(file.name).with_content(
          '/etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini')
      end

      it 'uses linuxbridge when configured to use it' do
        node.set['openstack']['network']['interface_driver'] = 'neutron.agent.linux.interface.BridgeInterfaceDriver'

        expect(chef_run).to render_file(file.name).with_content(
          '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini')
      end
    end
  end
end
