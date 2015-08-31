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

    ['/etc/puppetlabs/puppet/ssl', '/etc/puppet/ssl'].each do |path|
      if File.directory?(path)
        ssl_path = path
      end
    end

    certs_path or raise Puppet::ParseError, 'decom_clean_cert(): Could not determine location of certificates'
    master_certname = %x{hostname}.chomp

    cert_files = {
      :cacert => File.join(certs_path, 'certs', 'ca.cert'),
      :cert   => File.join(certs_path, 'certs', "#{master_certname}.pem"),
      :key    => File.join(certs_path, 'private_keys', "#{master_certname}.pem"),
    }

    cert_files.each do |k,f|
      File.readable?(f) or raise Puppet::ParseError, "decom_clean_cert(): Could not read #{k} file: #{f}"
    end

    Net::HTTP.start(cahost, 8140) do |http|
      http.use_ssl = true
      http.cert    = OpenSSL::X509::Certificate.new(cert_files[:cert])
      http.key     = OpenSSL::PKey::RSA.new(cert_files[:key])
      http.ca_file = cert_files[:cacert]

      request = Net::HTTP::Put.new("/#{env}/certificate_status/#{cert}", initheader = { 'Content-Type' => 'text/pson'})
      request.body = '{"desired_state":"revoked"}'
      response = http.request(request)
      response.code == '200' or raise Puppet::ParseError, "decom_clean_cert(): failed to revoke certificate. Response #{response.code}."

      request = Net::HTTP::Delete.new("/#{env}/certificate_status/#{cert}", initheader = { 'Accept' => 'pson'})
      response = http.request(request)
      response.code == '200' or raise Puppet::ParseError, "decom_clean_cert(): failed to delete certificate. Response #{response.code}."
    end
  end
end
