module Puppet::Parser::Functions
  newfunction(:decom_deactivate_node, :doc => <<-'ENDHEREDOC') do |args|
    Deactivates a server in PuppetDB
    ENDHEREDOC

    unless args.length == 1
      raise Puppet::ParseError, ("decom_deactivate_node(): Expects only 1 argument")
    end

    cert = args.shift
    cert.is_a?(String) or raise Puppet::ParseError, "decom_deactivate_node(); argument should be a string"

    #Queue the command and delay it for 2 mins.  This will ensure that the deactivation occures after
    #the catalog compilation has finished.  If we do it immediately, the catalog caching will revive the node.
    cmd = "echo 'puppet node deactivate #{cert}' | at now + 2 minutes"
    info("Deactivating node with command: #{cmd}")
    %x{ #{cmd} }
  end
end


