#!/bin/bash
#Copyright (c) 2012 Remy van Elst
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

DOMAIN=
PORT=
VALIDATECHAIN="no"
ERRORS=

usage() {
    echo "usage: $0 -d DOMAIN/IP -p PORT [-o]"
    echo "example:"
    echo "$0 -d raymii.org -p 443"
    echo "OK: Certificate from raymii.org is not on CRL: http://crl.comodoca.com/PositiveSSLCA2.crl and OCSP response is OK. (C1A3D8D00D72FCE483CD84759E9EC0BC)"
    echo "";
    echo "example to verify entire chain: "
    echo "$0 -d raymii.org -p 443 -o"
    echo "OK: Certificate from raymii.org is not on CRL: http://crl.comodoca.com/PositiveSSLCA2.crl and OCSP response is OK. (C1A3D8D00D72FCE483CD84759E9EC0BC)OK: Certificate from PositiveSSL CA 2 is not on CRL: http://crl.usertrust.com/AddTrustExternalCARoot.crl and OCSP response is OK. (076F124681459C28D548D697C40E001B)OK: Root Certificate (/C=SE/O=AddTrust AB/OU=AddTrust External TTP Network/CN=AddTrust External CA Root)"
    echo "";
    echo "$0 -d dropbox.com -p 443 -o"
    echo "OK: Certificate from dropbox.com is not on CRL: http://crl.godaddy.com/gds1-74.crl but does not supply a chain. (27EFF2E8A3B4C3)"
    echo "";
}   

# defining command line options
while getopts "hd:p:o" OPTION; do 
case $OPTION in
    h)
        usage
        exit 1
        ;;
    p)
        PORT=$OPTARG
        ;;
    d)
        DOMAIN=$OPTARG
        ;;
    o)
        VALIDATECHAIN="yes"
        ;;
    ?)
        usage
        exit 1
        ;;
    esac
done

if [[ -z $DOMAIN ]] || [[ -z $PORT ]]; then
    usage
    exit 1
fi

# First check if we can reach the host.
echo -n | openssl s_client -connect $DOMAIN:$PORT >/dev/null 2>/dev/null
if [ $? != 0 ]; then
    echo "CRITICAL: Cannot get certificate from ${DOMAIN}:${PORT}"
    exit 2;
fi

# Strip the openssl response to only show the certificates and not the other stuff
ALLCERTS=`echo -n | openssl s_client -showcerts -connect $DOMAIN:$PORT 2>/dev/null | awk '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/'` 
# Count how many certiicates we got
NOCERTSINCHAIN=`echo "$ALLCERTS" | grep "BEGIN CERTIFICATE" | wc -l`
#dump them in a file, so that we can echo it into the while loop which then does not start a subshell
echo "$ALLCERTS" > /tmp/$$.allcerts.pem

# define the function to get the certificates
function getcertificate {
    start_regex='-----BEGIN CERTIFICATE-----'
    end_regex='-----END CERTIFICATE-----'

    block_count=0
    line_count=0

    # this is the number we pass in later, the # certificate we want.
    CERTNUMBER=$1
    
    while read -r line; do

        if [[ $line =~ end_regex || -z $line ]]; then
            line_count=0
            continue
        fi

        if [[ $line =~ $start_regex ]]; then
            (( block_count++ ))
            continue
        fi

        (( line_count++ ))            

        if [[ $block_count == `expr $CERTNUMBER + 1` ]]; then
            break
        fi

        if [[ $line =~ $end_regex ]]; then
            continue
        fi

        if [[ $block_count == $CERTNUMBER ]]; then
            #echo "$line"
            CERT_BLOCK+="$line\n"
        fi


    done < "/tmp/$$.allcerts.pem"

    # Dirty trick to get all of the certificates in plain text.
    # ALLCERTSPLAIN=`openssl crl2pkcs7 -nocrl -certfile ./allcerts.pem | openssl pkcs7 -print_certs -text -noout`

    CERT_BLOCK="-----BEGIN CERTIFICATE-----\n$CERT_BLOCK-----END CERTIFICATE-----\n"    
    echo -e "$CERT_BLOCK"
    # If we don't clear the cert_block the certs are garbled.
    CERT_BLOCK=

}

#this is the actual testing
function testcert {
    CERT="$1"
    ISSUERCERT="$2"
     
     # get the common name from the subject
    CERTCN=`echo "$CERT" | openssl x509 -noout -subject 2>/dev/null | awk -F/CN= '{ print $2}'`
    if [ $? != 0 ]; then
        echo "CRITICAL: Cannot parse subject from ${DOMAIN}:${PORT} "
        return 2
        break
    fi

    #get the full subject, to compare with the issuer. If it's the same, 99% change of a root certificate 
    CERTSUBJECT=`echo "$CERT" | openssl x509 -noout -subject 2>/dev/null | awk -F"subject= " '{ print $2}'`
    if [ $? != 0 ]; then
        echo "CRITICAL: Cannot parse subject from ${DOMAIN}:${PORT} "
        return 2
        break
    fi

    #get the full issuer, to compare with the subject. If it's the same, 99% change of a root certificate 
    CERTISSUER=`echo "$CERT" | openssl x509 -noout -issuer 2>/dev/null | awk -F"issuer= " '{ print $2}'`
    if [ $? != 0 ]; then
        echo "CRITICAL: Cannot parse subject from ${DOMAIN}:${PORT} "
        return 2
        break
    fi

    # Now compare. If it matches, we give an OK and exit. ROOT certificates are self signed, so my check stops here.
    if [[ "$CERTSUBJECT" == "$CERTISSUER" ]]; then
        echo "OK: Root Certificate ($CERTSUBJECT) "
        return 0
        break
    fi

    # make plaintext out of certificate
    PLAINCERT=`echo "$CERT" | openssl x509 -noout -text 2>/dev/null`
    if [ $? != 0 ]; then
        echo "CRITICAL: Cannot decode certificate from ${CERTCN} "
        return 2
        break
    fi

    # get the serial number
    CERTSERIAL=`echo "$CERT" | openssl x509 -noout -serial 2>/dev/null | awk -F= '{print $2}'`
    if [ $? != 0 ]; then
        echo "CRITICAL: Cannot get certificate serial number from ${CERTCN} "
        return 2
        break
    fi
    # the serial below is on the Comodoca revoked list. 
    #CERTSERIAL=3AB8136060289E7DED08EB8049C95FF9
    # get the CRL URL (Only the first URL match, grep -m1)
    CRLURL=`echo "$PLAINCERT" | grep -m1 -o "http[:\|s:]//[a-zA-Z0-9].*.crl"`
    if [ $? != 0 ]; then
        echo "CRITICAL: Cannot get CRL url from ${CERTCN} "
        return 2
        break
    fi
    # download the CRL and put it in a variable
    CRLFILE=`wget --no-check-certificate -qO - "$CRLURL" | openssl crl -inform DER -noout -text 2>/dev/null`
    if [ $? != 0 ]; then
        echo "CRITICAL: Cannot parse CRL file from ${CERTCN} "
        return 2
        break
    fi

    # An OCSP is live, so it is newer than a CRL. First check if the OCSP check needs to be done.
    # Get the OCSP URL
    CERTOCSPURL=`echo "$CERT" | openssl x509 -noout -ocsp_uri`
    
    # if I get a certificate without chain, we cannot send the OCSP an issuer certficate because I don't know where to get it. 
    # Thus, that certificate must be directly signed by a browser trusted certificate.
    # We just try to check the CRL.
    if [[ "$NOCERTSINCHAIN" -eq 1 ]]; then
        CERTOCSPURL=
    fi

    # If the OCSP URL is here
    if [[ -n $CERTOCSPURL ]]; then

        # and if I have an issuercert as second arg
        # remember, OCSP needs a issuer certificate, if the domain doens't give it to me we cannot send it to the ocsp.
        if [[ -n $2 ]]; then

            # put the two in a temp file because the openssl ocsp doesn't handle sdtin
            echo "$ISSUERCERT" > /tmp/$$.issuer.crt
            echo "$CERT" > /tmp/$$.cert.crt
#            serial=`openssl x509 -serial -noout -in ./digidentity-accept-ivr.digidentity.eu.pem`; serial=${serial#*=}; serial="0x$serial";
            # line below is for debugging OCSP response, note the extra -text argument.
            #OCSPRESULT=`openssl ocsp -text -noverify -issuer /tmp/$$.issuer.crt -cert /tmp/$$.cert.crt -url $CERTOCSPURL`
            OCSPRESULT=`openssl ocsp -noverify -issuer /tmp/$$.issuer.crt -cert /tmp/$$.cert.crt -url $CERTOCSPURL 2>/dev/null`
            if [ $? != 0 ]; then
                # some issuer certificates are empty or not correct so we skip this check for now. Need to be fixed later on.
                #echo "CRITICAL: Error querying OCSP responsder "
                #return 2
                break
            fi
            # check the OCSP response as per RFC below, only if we don't get a revoked or unknown status we say its OK.
            # https://www.ietf.org/rfc/rfc2560.txt
            echo $OCSPRESULT | grep -q ": revoked"
            if [ $? == 0 ]; then
                echo "CRITICAL: OCSP response for ${CERTCN} is revoked: ${OCSPRESULT}" 
                return 2
                break
            fi
            echo $OCSPRESULT | grep -q ": unknown"
            if [ $? == 0 ]; then
                echo "CRITICAL: OCSP response for ${CERTCN} is unknown: ${OCSPRESULT}" 
                return 2
                break
            fi
        fi
    # if we have no OCSP url then we skip the OCSP
    else
        OCSPRESULT="empty"
    fi
    


    #check if the serial number of the requested certificate is on the CRL list.
    echo "$CRLFILE" | grep -q -A 1 "Serial Number: $CERTSERIAL"; 
    if [ $? == 0 ]; then 
        echo "CRITICAL: Certificate from ${CERTCN} is on CRL: ${CRLURL} (${CERTSERIAL}) "; 
        return 2
        break
    fi

    if [[ "$2" == "nochain" && "$NOCERTSINCHAIN" -eq 1 ]]; then
        echo "OK: Certificate from ${CERTCN} is not on CRL: ${CRLURL} but does not supply a chain. (${CERTSERIAL}) "; 
        return 1
        break
    elif [[ "$OCSPRESULT" == "empty" && "$NOCERTSINCHAIN" -eq 1 ]]; then
        echo "WARNING: Certificate from ${CERTCN} is not on CRL: ${CRLURL} but OCSP is not responding. (${CERTSERIAL}) "; 
        return 1
        break
        
    elif [[ "$OCSPRESULT" == "empty" ]]; then
        echo "OK: Certificate from ${CERTCN} is not on CRL: ${CRLURL} and has no OCSP. (${CERTSERIAL}) "; 
        return 0
        break
    fi

    # check still runs, so certificate is not on CRL and OCSP response is good.
    echo "OK: Certificate from ${CERTCN} is not on CRL: ${CRLURL} and OCSP response is OK. (${CERTSERIAL}) "; 
    return 0
    break

}

# We can safely parse the certificates as they come in because the root certificate must come last:
# http://webmasters.stackexchange.com/questions/27842/how-to-prevent-ssl-certificate-chain-not-sorted
# https://tools.ietf.org/html/rfc4346#section-7.4.2 - certificate_list

if [[ "$NOCERTSINCHAIN" -ne 1 ]]; then
    if [[ "$VALIDATECHAIN" == "yes" ]]; then
        for (( i = 1; i <= $NOCERTSINCHAIN; i++ )); do
            CERT=$(getcertificate "$i")
            J=`expr $i + 1`
            if [[ "$i" < "$$NOCERTSINCHAIN" ]]; then
                ISSUERCERT=$(getcertificate $J)
                CHECKS+=$(testcert "$CERT" "$ISSUERCERT")
            else
                CHECKS+=$(testcert "$CERT")
            fi
            EXCODE="$?"
            if [[ "$EXCODE" -ne 0 ]]; then
                EXITCODE=2
            fi
        done
    else
        for (( i = 1; i < 2; i++ )); do
            CERT=$(getcertificate $i)
            J=`expr $i + 1`
            ISSUERCERT=$(getcertificate $J)
            CHECKS+=$(testcert "$CERT" "$ISSUERCERT" )
            EXCODE="$?"
            if [[ "$EXCODE" -ne 0 ]]; then
                EXITCODE=2
            fi
        done
    fi
else
    CERT=$(getcertificate 1)
    CHECKS+=$(testcert "$CERT" "nochain")
    EXCODE="$?"
    if [[ "$EXCODE" -ne 0 ]]; then
        EXITCODE=2
    fi
fi
if [[ -f /tmp/$$.allcerts.pem ]]; then
    rm /tmp/$$.allcerts.pem
fi
if [[ -f /tmp/$$.issuer.crt ]]; then
    rm /tmp/$$.issuer.crt
fi
if [[ -f /tmp/$$.cert.crt ]]; then
    rm /tmp/$$.cert.crt
fi

echo "$CHECKS "
exit $EXITCODE