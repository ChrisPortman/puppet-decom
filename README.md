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

Note that the cleaning of certs, deactivation in PuppetDB and setting the node state in razor are processes that occur in custom functions.  Therefore these actions occur on the Puppet Master compiling the catalog.  This avoids the requirement of the server being decommissioned/reinstalled, requiring network access directly to the CA/PuppetDB/Razor server, which in distributed environment (like mine) may not be possible.  Only the Maaster compiling the catalog will need this access (which it should have anyway).

## Requirements
The Puppet masters will require the atd service installed and running.  This is required so that the Masters can queue delayed execution of the deactivation process.  If this process occurs during the catalog compilation, the caching of the catalog may revive it.  Therefore its delayed for a minute so that it occurs well after the catalog compilation has completed and after the server has recieved it and rebooted/shutdown.

## Examples
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


