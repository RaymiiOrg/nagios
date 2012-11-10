### Nagios plugin to check an OCSP server with hardcoded certificate 

This is a nagios plugin to check an OCSP server. It does so by having a PEM encoded certificate in the code, and the PEM encoded certificate of the issuer. This is sent to the OCSP server and the response is then parsed to give the correct nagios result. It is targeted at administrators who have their own OCSP and need to know when it is not working. 

The certificate is in the code because this saves going to a website and getting the certificate, the issuers certificate and then sending that to the OCSP server. It also can be used for certificates which are not public.

[Do you need a VPS for hosting nagios? InceptionHosting has very good VPS servers!](http://clients.inceptionhosting.com/aff.php?aff=083)

#### Download

[Download the plugin from my github](https://raw.github.com/RaymiiOrg/nagios/)  
[Download the plugin from raymii.org](https://raymii.org/cms/content/downloads/check_ocsp_hard.sh)  
[View the source code in the browser](https://raymii.org/cms/content/downloads/check_ocsp_hard.sh.txt)  

#### Installation and usage

This guide covers the steps needed for Ubuntu 10.04/12.04 and Debian 6. It should also work on other distro's, but make sure to modify the commands where needed (package installation for example).

First make sure you have the required tools:

    apt-get install gawk grep bash sed wget curl openssl

Place the script on the nagios host (I've placed it in */etc/nagios/plugins/*):

    wget -O */etc/nagios/plugins/check_ocsp_hard.sh http://raymii.org/cms/downloads/check_ocsp_hard.sh

Make sure that the script is executable:

    chmod +x /etc/nagios/plugins/check_ocsp_hard.sh

Now test it:

    /etc/nagios/plugins/check_ocsp_hard.sh
    OK: OCSP up and running - status of certificate for raymii.org GOOD by OCSP: http://ocsp.comodoca.com/

You have to put your own PEM encoded certificate in the script. You also need to place the PEM encoded certificate of the issuer of your certificate in the script. The variable `CERTTOCHECK` contains your certificate, the variable `ISSUERCERT` contains the issuer certificate.

A way of getting those certificate is via the following *openssl* command:

    echo -n |openssl s_client -connect $DOMAIN:$PORT -showcerts

where you of course replace $DOMAIN and $PORT with the domain and the port you want to query. If your certificate is directly signed by one of the browsers trusted certificates (you don't send a chain) you have to get that (issuer) certificate another way. 


When you've replaced my certificate with your own we are ready to configure it in Nagios.

Lets create a command definition:

    define command{
        command_name    ocsp_check_hard
        command_line    /etc/nagios-plugins/check_ocsp_hard.sh
    }

And a service check:

    define service {
            use                             generic-service
            host_name                       localhost
            service_description             OCSP check of $OCSP with hardcoded certificate of $DOMAIN
            contact                         nagiosadmin                 
            check_command                   ocsp_check_hard
    }

This defines a service check on the host *localhost*, and with contact *nagiosadmin*. Be sure to replace $OCSP with the name/url of the OCSP you hardcoded, and $DOMAIN with the name of the domain/name of certificate that is used. 

If you need to monitor multiple OCSP's (you maybe have more than one CA instance running) you need to have multiple copies of this script with different hardcoded certificates. You also need multiple commands and service checks.


