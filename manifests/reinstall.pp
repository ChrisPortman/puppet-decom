class decom::reinstall {
  #Deactivate the node in Puppetdb
  decom_deactivate_node($decom::certname)

  #Set node for reinstall in razor
  decom_razor_node($decom::razor_node, 'reinstall', $decom::razor_host)

  #Clean cert
  decom_clean_cert($decom::certname, $::environment, $decom::ca_host)

  exec { "REBOOT_${decom::certname}":
    command => '/usr/bin/reboot --force',
  }
}
