class decom (
  $mode,     #decommission|reinstall
  $confirm,  #Must match the certname
  $ca_host,
  $razor_host,
) {

  validate_string($mode, $confirm)

  unless $confirm == $certname {
    fail("Confirmation failed for decom")
  }

  case $mode {
    'decommission': { include decom::decommission }
    'reinstall':    { include decom::reinstall    }
    default:        { fail("Unknown decom mode: ${mode}. Valid options are 'decommission|reinstall'") }
  }
}

