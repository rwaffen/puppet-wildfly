require 'digest'

Puppet::Type.newtype(:wildfly_deploy) do

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
  end

  newparam(:source) do
  end

  newparam(:username) do
  end

  newparam(:password) do
  end

  newparam(:host) do
    defaultto '127.0.0.1'
  end

  newparam(:port) do
    defaultto 9990
  end

  newproperty(:content) do

    defaultto ''

    munge do |value|
      sha1sum(@resource[:source])
    end

    def insync?(is)
      should == is
    end

    def sha1sum(source)
      source_path = source.sub('file:', '')
      Digest::SHA1.hexdigest(File.read(source_path))
    end

  end

  autorequire(:service) do
    ['wildfly']
  end

end