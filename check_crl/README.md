### Nagios plugin to check CRL expiry in hours


This is a nagios plugin which you can use to check if a CRL (Certificate Revocation List, public list with revoked certificates) is still valid. This is based on the check_crl.py plugin from [Michele Baldessari](http://acksyn.org/?p=690). It is modified it so that it checks the time in minutes (for more precision) instead of days, it has a GMT time comparison bug fixed and I've added error handling so that if the plugin cannot get a crl file (because the webserver is down) it gives a Critical error in nagios.

#### Download

[Download the plugin from my github](https://github.com/RaymiiOrg/nagios)  
[Download the plugin from raymii.org](https://raymii.org/s/inc/downloads/check_crl.py)  

#### Install and Usage

This guide covers the steps needed for Ubuntu 10.04/12.04 and Debian 6. It should also work on other distro's, but make sure to modify the commands where needed. 

Make sure you have openssl, python3 and a module needed by the script installed on the nagios host:

    apt-get install python3 openssl python-m2crypto

Now place the script on the host. I've placed in */etc/nagios/plugins/check_crl.py*.

    wget -O /etc/nagios/plugins/check_crl.py http://raymii.org/s/inc/downloads/check_crl.py

Make sure the script is executable:

    chmod +x /etc/nagios/plugins/check_crl.py

Now test the script. I'm using the URL of the Comodo CA CRL file which is the CA that signed my certificate for raymii.org.


    /etc/nagios/plugins/check_crl.py -h http://crl.comodoca.com/PositiveSSLCA2.crl -w 480 -c 360
    OK CRL Expires in 5109 minutes (on Thu May  9 07:30:32 2013 GMT)

    /etc/nagios/plugins/check_crl.py -h http://crl.comodoca.com/PositiveSSLCA2.crl -w 5200 -c 360
    WARNING CRL Expires in 5108 minutes (on Thu May  9 07:30:32 2013 GMT)

    /etc/nagios/plugins/check_crl.py -h http://crl.comodoca.com/PositiveSSLCA2.crl -w 5000 -c 5300
    CRITICAL CRL Expires in 5108 minutes (on Thu May  9 07:30:32 2013 GMT)

Lets add the nagios command:

    define command{
        command_name    crl_check
        command_line    /etc/nagios-plugins/check_crl.py -u $ARG1$ -w $ARG2$ -c $ARG3$
    }

And lets add the command to a service check:

    define service {
            use                             generic-service
            host_name                       localhost
            service_description             Comodo PositiveSSL CA2 CRL
            contact                         nagiosadmin                 
            check_command                   crl_check!http://crl.comodoca.com/PositiveSSLCA2.crl!24!12
    }

The above service check runs on the nagios defined host "localhost", uses the (default) service template "generic-service" and had the contact "nagiosadmin". As you can see, the URL maps to $ARG1$, the warning hours to $ARG2$ and the critical hours to $ARG3$. This means that if the field *"Next Update:"* is less then 8 hours in the future you get a warning and if it is less then 6 hours you get a critical.

#### Changelog

03-04-2013:
- Changed time to minutes for more precision
- Fixed timezone bug by comparing GMT with GMT

06-11-2012:
- Changed checking interval from dates to hours
- Added error catching if a crl file cannot be retreived
