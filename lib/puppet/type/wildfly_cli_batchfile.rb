require 'puppet/parameter/boolean'

Puppet::Type.newtype(:wildfly_cli_batchfile) do
  desc 'Executes a JBoss-CLI batchfile'

  @isomorphic = false

  newparam(:batchfile, :namevar => true) do
    desc 'The path to the batchfile to execute'
  end

  newparam(:unless) do
    desc 'If this parameter is set, then CLI batchfile will only run if this batchfile returns true'
  end

  newparam(:onlyif) do
    desc 'If this parameter is set, then CLI batchfile will only run if this batchfile returns false'
  end

  newparam(:refreshonly, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'If this parameter is set, then CLI batchfile will only run if the resource was notified'
    defaultto false
  end

  newparam(:username) do
    desc 'JBoss Management User'
  end

  newparam(:password) do
    desc 'JBoss Management User Password'
  end

  newparam(:host) do
    desc 'Host of Management API. Defaults to 127.0.0.1'
    defaultto '127.0.0.1'
  end

  newparam(:port) do
    desc 'Management port. Defaults to 9990'
    defaultto 9990
  end

  newparam(:secure) do
    desc 'Use TLS to connect with the management API'
    defaultto false
  end

  newproperty(:executed) do
    desc 'Whether the batchfile should be executed or not'

    defaultto true

    def retrieve
      !provider.should_execute?
    end

    def sync
      provider.exec_command unless resource.refreshonly?
    end
  end

  def refresh
    return unless refreshonly? && provider.should_execute?

    Puppet.debug 'Executing wildfly_cli because resource received a refresh signal and refreshonly is true'
    provider.exec_command
  end
end
