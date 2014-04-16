# AXFR to nagios

Simple script which uses dig and a DNS zone transfer to create Nagios config.

## Usage

    ./axfr-to-nagios.sh DOMAIN NAMESERVER NAGIOS_MONITOR_HOST CONTACT_GROUPS

Example: 
    
    ./axfr-to-nagios.sh example.org 10.23.0.6 localhost admins

The command definition used is:

    define command {
        command_name    check_http_with_url
        command_line    /usr/lib/nagios/plugins/check_http -N -t 30 -H $ -u $ -w $ -c $
    }

Remember to change your DNS server config to allow your nagios server to do a ZONE transfer. For bind this would be:

    options {
        // [...]
       allow-transfer { 10.10.20.30 };
    };
