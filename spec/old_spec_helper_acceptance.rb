require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/puppet_install_helper'
require 'beaker/testmode_switcher/dsl'

module JBossCLI 
  extend RSpec::Core::SharedContext
  let(:jboss_cli) { "JAVA_HOME=#{test_data['java_home']} /opt/wildfly/bin/jboss-cli.sh --connect" }
end

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

def install_with_dependencies(host)
  copy_module_to(host, :source => PROJECT_ROOT, :module_name => 'wildfly')

  on host, puppet('module', 'install', 'puppetlabs-stdlib', '--force', '--version', '4.13.1')
  on host, puppet('module', 'install', 'jethrocarr-initfact')
end

def install_java(host)
  on host, puppet('resource', 'package', 'wget', 'ensure=installed')
  on host, 'wget https://doc-0o-9c-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/7eelvqree5q8ski1d13625m75bahknja/1568980800000/18214363628765128033/*/1tkj8_kAFRCNxZLqOaqU6XRj6ac0iEjer?e=download -O /var/cache/wget/OpenJDK8U-jdk_x64_linux_hotspot_8u192b12.tar.gz && tar -C /opt -zxvf /var/cache/wget/OpenJDK8U-jdk_x64_linux_hotspot_8u192b12.tar.gz'
end

RSpec.configure do |c|
  c.include JBossCLI
  c.add_setting :test_data, :default => {}
  c.formatter = :documentation
  c.before :suite do
    run_puppet_install_helper

    master = find_at_most_one_host_with_role(hosts, 'master')

    if master.nil?
      hosts.each do |host|
        install_with_dependencies(host)
        install_java(host)
      end
    else
      install_with_dependencies(master)

      on master, 'yum install -y puppetserver'
      on master, 'echo "*" > /etc/puppetlabs/puppet/autosign.conf'
      on master, puppet('resource', 'service', 'firewalld', 'ensure=stopped', 'enable=false')
      on master, puppet('resource', 'service', 'puppetserver', 'ensure=running', 'enable=true')

      puppet_server_fqdn = fact_on('master', 'fqdn')

      hosts.agents.each do |agent|
        install_java(agent)

        config = {
          'main' => {
            'server' => puppet_server_fqdn.to_s
          }
        }

        configure_puppet(config)
      end
    end
  end
end

def test_data
  RSpec.configuration.test_data
end

profile = ENV['TEST_profile'] || 'wildfly:9.0.2'

data = {}

case profile

when /(wildfly):(\d{1,}\.\d{1,}\.\d{1,})/
  data['distribution'] = Regexp.last_match(1)
  data['version'] = Regexp.last_match(2)
  data['install_source'] = "http://download.jboss.org/wildfly/#{data['version']}.Final/wildfly-#{data['version']}.Final.tar.gz"
  data['service_name'] = 'wildfly'
when /(jboss-eap):(\d{1,}\.\d{1,})/
  data['distribution'] = Regexp.last_match(1)
  data['version'] = Regexp.last_match(2)
  data['install_source'] = "http://10.0.2.2:9090/jboss-eap-#{data['version']}.tar.gz"
  data['service_name'] = (data['version'].to_f < 7.0 ? 'jboss-as' : 'jboss-eap')
when 'custom'
  data['distribution'] = ENV.fetch('TEST_distribution', nil)
  data['version'] = ENV.fetch('TEST_version', nil)
  data['install_source'] = ENV.fetch('TEST_install_source', nil)
  data['service_name'] = ENV.fetch('TEST_service_name', nil)
end

data['java_home'] = '/opt/jdk8u192-b12/'

RSpec.configuration.test_data = data
