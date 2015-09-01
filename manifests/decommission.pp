class decom::decommission {
  #Deactivate the node in Puppetdb
  decom_deactivate_node($decom::certname)

  #Set node for reinstall in razor
  decom_razor_node($decom::razor_node, 'decommission', $decom::razor_host)

  exec { "DHCP_RELEASE_${decom::certname}":
    command => '/sbin/dhclient -r',
  }

  #Clean cert
  decom_clean_cert($decom::certname, $::environment, $decom::ca_host)

  exec { "SHUTDOWN_${decom::certname}":
    command => '/usr/bin/halt --force',
    require => Exec["DHCP_RELEASE_${decom::certname}"],
  }
}

