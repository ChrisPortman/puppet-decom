class decom::decommission {
  if $decom::enable_puppetdb_clean {
    #Deactivate the node in Puppetdb
    decom_deactivate_node($decom::certname)
  }

  if $decom::enable_razor_update {
    #Set node for reinstall in razor
    decom_razor_node($decom::razor_node, 'decommission', $decom::razor_host)
  }

  if $decom::enable_cert_clean {
    #Clean cert
    decom_clean_cert($decom::certname, $::environment, $decom::ca_host)
  }

  # There is inconsistancy with regards to what dhclient files exist.
  # Test for different combinations and run the ones that apply
  $eth0_conf_file     = '/etc/dhcp/dhclient-eth0.conf'
  $eth0_lease_file    = '/var/lib/dhclient/dhclient-eth0.leases'
  $generic_conf_file  = '/etc/dhcp/dhclient.conf'
  $generic_lease_file = '/var/lib/dhclient/dhclient.leases'

  exec { "DHCP_RELEASE_${decom::certname}-1":
    command => "dhclient -cf ${eth0_conf_file}-lf ${eth0_lease_file}-r",
    path    => '/usr/bin:/usr/sbin:/sbin:/bin',
    onlyif  => [ "test -f  ${eth0_conf_file}", "test -f ${eth0_lease_file}" ],
    before  => Exec["SHUTDOWN_${decom::certname}"],
  }

  exec { "DHCP_RELEASE_${decom::certname}-2":
    command => "dhclient -cf ${generic_conf_file}-lf ${generic_lease_file}-r",
    path    => '/usr/bin:/usr/sbin:/sbin:/bin',
    onlyif  => [ "test -f  ${generic_conf_file}", "test -f ${generic_lease_file}" ],
    before  => Exec["SHUTDOWN_${decom::certname}"],
  }

  exec { "DHCP_RELEASE_${decom::certname}-3":
    command => "dhclient -cf ${generic_conf_file}-lf ${eth0_lease_file}-r",
    path    => '/usr/bin:/usr/sbin:/sbin:/bin',
    onlyif  => [ "test -f  ${generic_conf_file}", "test -f ${eth0_lease_file}" ],
    before  => Exec["SHUTDOWN_${decom::certname}"],
  }

  exec { "DHCP_RELEASE_${decom::certname}-4":
    command => "dhclient -cf ${eth0_conf_file}-lf ${generic_lease_file}-r",
    path    => '/usr/bin:/usr/sbin:/sbin:/bin',
    onlyif  => [ "test -f  ${eth0_conf_file}", "test -f ${generic_lease_file}" ],
    before  => Exec["SHUTDOWN_${decom::certname}"],
  }

  exec { "SHUTDOWN_${decom::certname}":
    command => '/usr/bin/halt -p',
  }
}

