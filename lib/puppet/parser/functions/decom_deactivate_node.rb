module Puppet::Parser::Functions

  newfunction(:decom_deactivate_node, :doc => <<-'ENDHEREDOC') do |args|
    Deactivates a server in PuppetDB
    ENDHEREDOC

    unless args.length == 1
      raise Puppet::ParseError, ("decom_deactivate_node(): Expects only 1 argument")
    end

    cert = args.shift
    cert.is_a?(String) or raise Puppet::ParseError, "decom_deactivate_node(); argument should be a string"

    %x{puppet node deactivate #{cert}}
  end
end


