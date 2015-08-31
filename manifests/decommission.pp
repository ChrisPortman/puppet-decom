class decom::decommission {
  #Deactivate the node in Puppetdb
  decom_deactivate_node($::certname)

  #Set node for reinstall in razor
  decom_razor_node($decom::razor_node, 'decommission', $decom::razor_host)

  exec { "DHCP_RELEASE_${::certname}":
    command => '/sbin/dhclient -r',
  }

  #Clean cert
  decom_clean_cert($::certname, $::environment, $decom::ca_host)

  exec { "REBOOT_${::certname}":
    command => '/usr/bin/reboot --force',
    require => Exec["DHCP_RELEASE_${::certname}"],
  }
}

