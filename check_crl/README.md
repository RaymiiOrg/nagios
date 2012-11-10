### Nagios plugin to check CRL expiry in hours

This is a nagios plugin which you can use to check if a CRL (Certificate Revocation List, public list with revoked certificates) is still valid. This is based on the check_crl.py plugin from [Michele Baldessari](http://acksyn.org/?p=690). I've modified it so that it checks the time in hours (for more precision) instead of days, and I've added error handling so that if the plugin cannot get a crl file (because the webserver is down) it gives a Critical error in nagios.

[Page on Raymii.org](https://raymii.org/cms/p_Nagios_plugin_to_check_crl_expiry_in_hours)

#### Download

[Download the plugin from my github](https://raw.github.com/RaymiiOrg/nagios/master/check_crl.py)  
[Download the plugin from raymii.org](https://raymii.org/cms/content/downloads/check_crl.py)  
[View the source code in the browser](https://raymii.org/cms/content/downloads/check_crl.py.txt)  
   
#### Install and Usage

This guide covers the steps needed for Ubuntu 10.04/12.04 and Debian 6. It should also work on other distro's, but make sure to modify the commands where needed. 

Make sure you have openssl, python3 and a module needed by the script installed on the nagios host:

    apt-get install python3 openssl python-m2crypto

Now place the script on the host. I've placed in */etc/nagios/plugins/check_crl.py*.

    wget -O /etc/nagios/plugins/check_crl.py http://raymii.org/cms/content/downloads/check_crl.py

Make sure the script is executable:

    chmod +x /etc/nagios/plugins/check_crl.py

Now test the script. I'm using the URL of the Comodo CA CRL file which is the CA that signed my certificate for raymii.org.


    /etc/nagios/plugins/check_crl.py -h http://crl.comodoca.com/PositiveSSLCA2.crl -w 60 -c 30
    OK CRL Expires in 76 hours (3 days) (on 2012-11-09 21:06:42)

    /etc/nagios/plugins/check_crl.py -h http://crl.comodoca.com/PositiveSSLCA2.crl -w 90 -c 80
    CRITICAL CRL Expires in 76 hours (3  days ) (on 2012-11-09 21:06:42)

    /etc/nagios/plugins/check_crl.py -h http://crl.comodoca.com/PositiveSSLCA2.crl -w 90 -c 60
    WARNING CRL Expires in 76 hours (3  days ) (on 2012-11-09 21:06:42)

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

The above service check runs on the nagios defined host "localhost", uses the (default) service template "generic-service" and had the contact "nagiosadmin". As you can see, the URL maps to $ARG1$, the warning hours to $ARG2$ and the critical hours to $ARG3$. This means that if the field *"Next Update:"* is less then 24 hours in the future you get a warning and if it is less then 12 hours you get a critical.

#### Changelog

06-11-2012:
- Changed checking interval from dates to hours
- Added error catching if a crl file cannot be retreived.

#### Bugs

- The CRL file must be a DER encoded CRL file. I'm planning to also add a switch/check to see if it is a DER or PEM file and handle it correctly, but for now it only handles DER CRL files.

#### License

Unknown.
