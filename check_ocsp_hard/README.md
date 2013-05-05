### Nagios plugin to check an OCSP server with hardcoded certificate 


This is a nagios plugin to check an OCSP server. It does so by having either a PEM encoded certificate in the code, and the PEM encoded certificate of the issuer in the code, or by using two given PEM files. This is sent to the OCSP server and the response is then parsed to give the correct nagios result. It is targeted at administrators who have their own OCSP and need to know when it is not working. 

This version has contributions from [Pali Sigurdsson](https://github.com/palli/).

[Do you need a VPS for hosting nagios? InceptionHosting has very good VPS servers!](http://clients.inceptionhosting.com/aff.php?aff=083)

#### Download

[Download the plugin from my github](https://github.com/RaymiiOrg/nagios)  
[Download the plugin from raymii.org](https://raymii.org/s/inc/downloads/check_ocsp.sh)  

#### Usage

`./check_ocsp.sh`:

- `-H host_name` - remote host to check
- `-P port` - port to use
- `--noverify` - Don't verify if certificate is valid
- `--max-age 4800` - alert if certificate is about to expire
- `--cert filename` - use this cert file instead of the hardcoded one
- `--issuer filename.pem` - use this issuer certificate instead of the hardcoded one
- `--verbose` - handy for troubleshooting, echos the exact openssl command used


#### Installation

This guide covers the steps needed for Ubuntu 10.04/12.04 and Debian 6. It should also work on other distro's, but make sure to modify the commands where needed (package installation for example).

First make sure you have the required tools:

    apt-get install gawk grep bash sed wget curl openssl

Place the script on the nagios host (I've placed it in */etc/nagios/plugins/*):

    wget -O */etc/nagios/plugins/check_ocsp_hard.sh http://raymii.org/s/inc/downloads/check_ocsp_hard.sh

Make sure that the script is executable:

    chmod +x /etc/nagios/plugins/check_ocsp_hard.sh

Now test it:

    /etc/nagios/plugins/check_ocsp_hard.sh
    OK: OCSP up and running - status of certificate for raymii.org GOOD by OCSP: http://ocsp.comodoca.com/

#### Nagios config

Here's some example nagios config:

Lets create a command definition:

    define command{
        command_name    check_ocsp
        command_line    /etc/nagios-plugins/check_ocsp.sh -H $USER1$ -p $USER2$ --cert $USER3$ --issuer $USER4$
    }

And a service check:

    define service {
            use                             generic-service
            host_name                       localhost
            service_description             OCSP check of $OCSP for $DOMAIN
            contact                         nagiosadmin                 
            check_command                   check_ocsp!raymii.org!443!/etc/ssl/certs/raymiiorg.pem!/etc/ssl/certs/comodo.pem
    }


Or if you use a hardcoded certificate:

    define command{
        command_name    check_ocsp_hard
        command_line    /etc/nagios-plugins/check_ocsp.sh
    }

    define service {
            use                             generic-service
            host_name                       localhost
            service_description             OCSP check of $OCSP for $DOMAIN with hardcoded certificate
            contact                         nagiosadmin                 
            check_command                   check_ocsp_hard
    }



