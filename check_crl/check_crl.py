#!/usr/bin/python3

# Jeroen Nijhof <jnijhof@digidentity.eu>
# Changelog: - fixed timezone bug by comparing GMT with GMT
#            - changed hours to minutes for even more precision

# Remy van Elst - raymii.org - 2012
# 05.11.2012
# Changelog: - check with hours instead of dates for more precision,
#            - URL errors are now also catched as nagios exit code.

# Michele Baldessari - Leitner Technologies - 2011
# 23.08.2011

import time
import datetime
import getopt
import os
import pprint
import subprocess
import sys
import tempfile
import urllib.request, urllib.parse, urllib.error

def check_crl(url, warn, crit):
    tmpcrl = tempfile.mktemp("crl")
    #request = urllib.request.urlretrieve(url, tmpcrl)
    try:
        urllib.request.urlretrieve(url, tmpcrl)
    except:
        print ("CRITICAL: CRL could not be retreived: %s" % url)
        sys.exit(2)

    ret = subprocess.check_output(["/usr/bin/openssl", "crl", "-inform", "DER", "-noout", "-nextupdate", "-in", tmpcrl])
    nextupdate = ret.strip().decode('utf-8').split("=")
    os.remove(tmpcrl)
    eol = time.mktime(time.strptime(nextupdate[1],"%b %d %H:%M:%S %Y GMT"))
    today = time.mktime(datetime.datetime.utcnow().timetuple())
    seconds = eol - today
    minutes = int(seconds / 60)
    if  minutes > crit and minutes <= warn:
        msg = "WARNING CRL Expires in %s minutes (on %s GMT)" % (minutes, time.asctime(time.localtime(eol)))
        exitcode = 1
    elif minutes <= crit:
        msg = "CRITICAL CRL Expires in %s minutes (on %s GMT)" % (minutes, time.asctime(time.localtime(eol)))
        exitcode = 2
    else:
        msg = "OK CRL Expires in %s minutes (on %s GMT)" % (minutes, time.asctime(time.localtime(eol)))
        exitcode = 0

    print (msg)
    sys.exit(exitcode)

def usage():
    print ("check_crl.py -h|--help -v|--verbose -u|--url=<url> -w|--warning=<minutes> -c|--critical=<minutes>")
    print ("")
    print ("Example, if you want to get a warning if a CRL expires in 8 hours and a critical if it expires in 6 hours:")
    print ("./check_crl.py -u \"http://domain.tld/url/crl.crl\" -w 480 -c 360")

def main():
    try:
        opts, args = getopt.getopt(sys.argv[1:], "hu:w:c:", ["help", "url=", "warning=", "critical="])
    except getopt.GetoptError as err:
        usage()
        sys.exit(2)
    url = None
    warning = None
    critical = None
    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("-u", "--url"):
            url = a
        elif o in ("-w", "--warning"):
            warning = a
        elif o in ("-c", "--critical"):
            critical = a
        else:
            assert False, "unhandled option"

    if url != None and warning != None and critical != None:
        check_crl(url, int(warning), int(critical))
    else:
        usage()
        sys.exit(2)


if __name__ == "__main__":
    main()