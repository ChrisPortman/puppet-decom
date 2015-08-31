class decom::reinstall {
  #Deactivate the node in Puppetdb
  decom_deactivate_node($::certname)

  #Set node for reinstall in razor
  decom_razor_node($decom::razor_node, 'reinstall', $decom::razor_host)

  #Clean cert
  decom_clean_cert($::certname, $::environment, $decom::ca_host)

  exec { "REBOOT_${::certname}":
    command => '/usr/bin/reboot --force',
  }
}
