require File.expand_path(File.join(File.dirname(__FILE__), '..', 'wildfly'))

Puppet::Type.type(:wildfly_cli_batchfile).provide :http_api, :parent => Puppet::Provider::Wildfly do
  desc 'Uses JBoss HTTP API to execute a JBoss-CLI batchfile'

  def exec_command
    debug "Running: run-batch --file=#{@resource[:command]}"
    # cli.exec("run-batch --file=#{@resource[:command]}")
    cli.exec("run-batch")
  end

  def should_execute?
    unless_eval = true
    unless_eval = cli.evaluate(@resource[:unless]) unless @resource[:unless].nil?

    onlyif_eval = false
    onlyif_eval = cli.evaluate(@resource[:onlyif]) unless @resource[:onlyif].nil?

    onlyif_eval || !unless_eval || (@resource[:unless].nil? && @resource[:onlyif].nil?)
  end
end
