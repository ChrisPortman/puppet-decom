# puppet-decom

This module can be used to decommission or reinstall a Puppeted machine.

It has to modes:
   * *reinstall*: This will
      * Clean the client certs on the master (revoke and delete)
      * Deactivate the node in PuppetDB
      * Set the node to reinstall in razor
      * Reboot the server
   * *decommission*: This will      
      * Clean the client certs on the master (revoke and delete)
      * Deactivate the node in PuppetDB
      * Delete the node from Razor
      * Release any DHCP leases
      * Shutdown the server

Examples:
```
# Decommission a server
class { 'decom':
  confirm    => $::fqdn,
  mode       => 'decommission',
  razor_node => $::razor_node_id,
  ca_host    => $ca_server_fqdn,
  razor_host => $razor_server_fqdn,
}

# Reinstall a server
class { 'decom':
  confirm    => $::fqdn,
  mode       => 'reinstall',
  razor_node => $::razor_node_id,
  ca_host    => $ca_server_fqdn,
  razor_host => $razor_server_fqdn,
}
```

## Important parameters
### confirm
The confirm parameter must match $::truster['certname'].  This ensures that a server can only decommission itself and that the action is intentional.

## Suggested Usage
Use an external fact to trigger the the decommission/reinstall.  E.g.
```
#/etc/facter/facts.d/decom.txt

decommission=server1.example.com
```

Then add to your site.pp
```
node default {
  #First look for a 'decommission' or 'reinstall' fact.
  #if present, use the decom class to gracefully remove the node
  #from puppet and take the appropriate action in razor.  The
  #class will then reboot/shutdown the node.

  #Note the value for the decommission/reinstall fact must match the
  #FQDN of the machine.  This is a validation step to ensure that people
  #are killing machines they intend to.
  if $::decommission {
    class { 'decom':
      confirm    => $::decommission,
      mode       => 'decommission',
      razor_node => $::razor_node_id,
    }
  }
  elsif $::reinstall {
    class { 'decom':
      confirm    => $::reinstall,
      mode       => 'reinstall',
      razor_node => $::razor_node_id,
    }
  }
  else {
    # do a normal run
  }
```
Note that this method, for razor integration depends on the razor node id being available as a fact.  I suggest ammending the razor post install scripts to write the node ID to an external facts file so that it is usable here (plus its just handy).


