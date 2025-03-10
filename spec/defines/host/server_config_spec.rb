# frozen_string_literal: true

require 'spec_helper'

shared_examples 'missing required parameter should raise error' do |parameter_name|
  describe "with #{parameter_name} missing" do
    let(:params) do
      super().merge({ :"#{parameter_name}" => :undef })
    end

    it { is_expected.to compile.and_raise_error(/#{parameter_name} is required/) }
  end
end

describe 'wildfly::host::server_config' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          {
            :fqdn => 'appserver.localdomain',
            :wildfly_is_running => true,
          }
        )
      end
      let(:pre_condition) { 'include wildfly' }
      let(:title) { 'sample-server' }
      let(:params) do
        {
          server_group: 'sample-server-group',
          controller_address: '192.168.33.10',
          hostname: 'appserver.localdomain',
          username: 'app',
          password: 'app',
        }
      end

      context 'with ensure present' do
        it_behaves_like 'missing required parameter should raise error', 'server_group'
        it_behaves_like 'missing required parameter should raise error', 'hostname'
        it_behaves_like 'missing required parameter should raise error', 'username'
        it_behaves_like 'missing required parameter should raise error', 'password'
        it_behaves_like 'missing required parameter should raise error', 'controller_address'

        context 'with required parameters' do
          it do
            is_expected.to contain_wildfly_resource("/host=appserver.localdomain/server-config=#{title}")
          end

          context 'with start_server_after_created = true' do
            it do
              is_expected.to contain_wildfly_cli("/host=appserver.localdomain/server-config=#{title}:start(blocking=true)")
                .with({
                  :onlyif => "(result != STARTED) of /host=appserver.localdomain/server-config=#{title}:read-attribute(name=status)"
                })
            end
          end

          context 'with start_server_after_created = false' do
            let(:params) do
              super().merge({ :start_server_after_created => false })
            end

            it do
              is_expected.not_to contain_wildfly_cli("/host=appserver.localdomain/server-config=#{title}:start(blocking=true)")
            end
          end
        end
      end

      context 'with ensure absent' do
        let(:params) do
          super().merge({
            :ensure => 'absent',
            :wildfly_dir => '/opt/wildfly',
            :host_config => 'host-slave.xml',
          })
        end

        context 'with wildfly running' do
          it do
            is_expected.to contain_wildfly_cli("/host=appserver.localdomain/server-config=#{title}:stop(blocking=true)")
              .with({
                  :onlyif => "(result != STOPPED) of /host=appserver.localdomain/server-config=#{title}:read-attribute(name=status)"
                })

            is_expected.to contain_wildfly_resource("/host=appserver.localdomain/server-config=#{title}")
              .with({ :ensure => 'absent' })

            is_expected.not_to contain_augeas("manage-host-controller-server-#{title}")
          end
        end

        context 'with wildfly stopped' do
          let(:facts) do
            super().merge({
              :wildfly_is_running => false,
            })
          end

          it do
            is_expected.to contain_augeas("manage-host-controller-server-#{title}")
              .with({
                :lens    => 'Xml.lns',
                :incl    => "/opt/wildfly/domain/configuration/host-slave.xml",
                :changes => "rm host/servers/server[#attribute/name='#{title}']",
                :onlyif  => "match host/servers/server[#attribute/name='#{title}'] size != 0",
              })
          end
        end
      end
    end
  end
end
