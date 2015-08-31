require 'net/http'
require 'net/https'

module Puppet::Parser::Functions
  newfunction(:decom_razor_node, :doc => <<-'ENDHEREDOC') do |args|
    Decommissions or reinstalls the node in Razor
    USAGE: decom_razor_node(node_id, action, razor_host)
    ENDHEREDOC

    unless args.length == 3
      raise Puppet::ParseError, ("decom_clean_cert: Expects at exactly 3 arguments, the razor node ID, the action (decommission|reinstall) and the hostname of the Razor server")
    end

    node   = args.shift.to_s
    action = args.shift
    host   = args.shift

    action.is_a?(String) or raise Puppet::ParseError, "decom_clean_cert(): second argument must be a string"
    host.is_a?(String)   or raise Puppet::ParseError, "decom_clean_cert(): third argument must be a string"

    /^\d+$/.match(node) or raise Puppet::ParseError, 'decom_razor_node(): first argument must be a number'
    ['decommission', 'reinstall'].include?(action) or raise Puppet::ParseError, 'decom_razor_node(): second argument must be one of "reinstall" or "decommission".'

    Net::HTTP.start(host) do |http|
      case action
      when 'reinstall'
        request = Net::HTTP::Post.new("/api/reinstall-node", initheader = { 'Content-Type' => 'application/json' })
      when 'decommission'
        request = Net::HTTP::Post.new("/api/delete-node", initheader = { 'Content-Type' => 'application/json' })
      else
        raise Puppet::ParseError, 'decom_razor_node(): second argument must be one of "reinstall" or "decommission".'
      end

      request.body = JSON.dump({'name' => "node#{node}"})
      response = http.request(request)
      response.code == '200' or raise Puppet::ParseError, "decom_razor_node(): failed to #{action} node. Response #{response.code}."
    end
  end
end
