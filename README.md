# My Nagios Plugins

This is a repo with my nagios plugins. 

## Plugins:

- [check_crl - check when a CRL needs to be updated and alert if it is lower than the set threshold in minutes.](https://raymii.org/cms/p_Nagios_plugin_to_check_crl_expiry_in_hours)
- [check_ocsp_hard - check if an OCSP is working, with the certificate PEM and issuer PEM in the check.](https://raymii.org/cms/p_Nagios_plugin_to_check_OCSP)
- [check_hsm_advanced is used to monitor Safenet HSM's, (ProtectServer).](https://raymii.org/s/software/Nagios_Plugin_to_check_a_Safenet_HSM.html)
- check_dns_zone_sync - simple DNS zone sync check, compares domain Serial from master DNS server to slave DNS servers serial
- check_ossec_agents - checks an ossec server if there are disconnected agents and list them.
- AXFR-to-nagios - Simple script which converts a DIG zonetransfer to a nagios HTTP check config file
- check_updates - simple checks for apt, yum and pacman updates.
