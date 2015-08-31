require 'net/http'
require 'net/https'

module Puppet::Parser::Functions
  newfunction(:decom_clean_cert, :doc => <<-'ENDHEREDOC') do |args|
    Cleans the supplied certificate from the Puppet CA.
    USAGE: decom_clean_cert(certname, environment, cahost)
    ENDHEREDOC

    unless args.length == 3
      raise Puppet::ParseError, ("decom_clean_cert: Expects at exactly 3 arguments, the certname, the environment of the server and the hostname of the CA")
    end

    cert   = args.shift
    env    = args.shift
    cahost = args.shift

    cert.is_a?(String)   or raise Puppet::ParseError, "decom_clean_cert(): first argument must be a string"
    env.is_a?(String)    or raise Puppet::ParseError, "decom_clean_cert(): second argument must be a string"
    cahost.is_a?(String) or raise Puppet::ParseError, "decom_clean_cert(): third argument must be a string"

    ssl_path = nil
    ['/etc/puppetlabs/puppet/ssl', '/etc/puppet/ssl'].each do |path|
      if File.directory?(path)
        ssl_path = path
      end
    end

    ssl_path or raise Puppet::ParseError, 'decom_clean_cert(): Could not determine location of certificates'
    master_certname = %x{hostname}.chomp

    cert_files = {
      :cacert => File.join(ssl_path, 'certs', 'ca.pem'),
      :cert   => File.join(ssl_path, 'certs', "#{master_certname}.pem"),
      :key    => File.join(ssl_path, 'private_keys', "#{master_certname}.pem"),
    }

    cert_files.each do |k,f|
      File.readable?(f) or raise Puppet::ParseError, "decom_clean_cert(): Could not read #{k} file: #{f}"
      info("#{k} file is #{f}")
    end

    info("Connecting to CA at #{cahost}")
    Net::HTTP.start(cahost, 8140, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      info("Connected to CA at #{cahost}")
      http.cert    = OpenSSL::X509::Certificate.new(File.read(cert_files[:cert]))
      http.key     = OpenSSL::PKey::RSA.new(File.read(cert_files[:key]))
      http.ca_file = cert_files[:cacert]
      path = "/#{env}/certificate_status/#{cert}"
      info("Decom cert cleaning using path: #{path}")

      request = Net::HTTP::Put.new(path, initheader = { 'Content-Type' => 'text/pson'})
      request.body = JSON.dump({'desired_state' => 'revoked'})
      response = http.request(request)
      (response.code.to_i >= 200 and response.code.to_i <= 299) or
       raise Puppet::ParseError, "decom_clean_cert(): failed to revoke certificate. Response #{response.code}."

      request = Net::HTTP::Delete.new(path, initheader = { 'Accept' => 'pson'})
      response = http.request(request)
      (response.code.to_i >= 200 and response.code.to_i <= 299) or
        raise Puppet::ParseError, "decom_clean_cert(): failed to delete certificate. Response #{response.code}."
    end
  end
end
