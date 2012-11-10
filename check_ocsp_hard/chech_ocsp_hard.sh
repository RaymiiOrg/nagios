#!/bin/bash
# Hardcoded OCSP check
# Hard coded to certificate of raymii.org
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


OCSPURL="http://ocsp.comodoca.com/"
CERTCN="raymii.org"
# Certificate from raymii.org as on 08-NOV-2012
CERTTOCHECK='-----BEGIN CERTIFICATE-----
MIIE6TCCA9GgAwIBAgIRAMGj2NANcvzkg82EdZ6ewLwwDQYJKoZIhvcNAQEFBQAw
czELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxGTAXBgNV
BAMTEFBvc2l0aXZlU1NMIENBIDIwHhcNMTIwNjI1MDAwMDAwWhcNMTQwNjI1MjM1
OTU5WjBOMSEwHwYDVQQLExhEb21haW4gQ29udHJvbCBWYWxpZGF0ZWQxFDASBgNV
BAsTC1Bvc2l0aXZlU1NMMRMwEQYDVQQDEwpyYXltaWkub3JnMIIBIjANBgkqhkiG
9w0BAQEFAAOCAQ8AMIIBCgKCAQEA10FohUnfpkPX9BTHT6DJPp4VBZulGQyCwFSS
rovT4sP8p+AZC2QlhwkvmgYDoehE4dt+BblBVG1Yq6VXSAJHHWr93HIr+IcVSyeG
Y1xEfJM2+ZJM0Y0TQmbweC92pc5bdK9ACUPjaxrMPdgMRk7QXo38+WP7FBGoKMvT
Tblx6LM0H5r7TLqjR3638ZQVHCQIZas7D8iPOPR2548Hg8/88X4/V/OJCLFtEvfd
0esthJ58saEBCragRNFg4cqf8pZby+YI11f6ydQ/VmjWyaqdjhSm/gyeW7+4uDp1
p1YcWHTLnLRrZMEgS+6hOfmrY6dClzQ1LGB9o0uJhOwFUuf02wIDAQABo4IBmzCC
AZcwHwYDVR0jBBgwFoAUmeRAX2sUXj4F2d3TY1T8Yrj3AKwwHQYDVR0OBBYEFDpL
KT5kugQGQ9hsYM1p0/eejotPMA4GA1UdDwEB/wQEAwIFoDAMBgNVHRMBAf8EAjAA
MB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjBGBgNVHSAEPzA9MDsGCysG
AQQBsjEBAgIHMCwwKgYIKwYBBQUHAgEWHmh0dHA6Ly93d3cucG9zaXRpdmVzc2wu
Y29tL0NQUzA7BgNVHR8ENDAyMDCgLqAshipodHRwOi8vY3JsLmNvbW9kb2NhLmNv
bS9Qb3NpdGl2ZVNTTENBMi5jcmwwbAYIKwYBBQUHAQEEYDBeMDYGCCsGAQUFBzAC
hipodHRwOi8vY3J0LmNvbW9kb2NhLmNvbS9Qb3NpdGl2ZVNTTENBMi5jcnQwJAYI
KwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNvbW9kb2NhLmNvbTAlBgNVHREEHjAcggpy
YXltaWkub3Jngg53d3cucmF5bWlpLm9yZzANBgkqhkiG9w0BAQUFAAOCAQEATAfY
a9H1HGUK3UekE7py7v/i+UIcC+GiQt3VYFLFD2kDFk3pU9ZlpCl1gsNiGiUcoGLT
Hovwy64Rj0KMxQFugL+zyfzzD7MuRDqxbdPGrsnTRTGW2onfm4MrQI5WOC69DbKx
wVGKscaQ+X43EGATOvoPXJ5vqkspQn+Wh/QIiliWjFcBbMAOYWTQRn9EMb8sFyhz
Oe/Xm2oyNZRW+o1obb4CFk7gcBsJ//OGDmKBiQMO5RiIivaY6wUHgyvPM+guQ0N9
fyDed0L9Oai24fvoHLz8JK3rxgEi/n4tSXb4j2ShS5B71oJp9XyDO8DR5a7QD3qs
jJoiuwX8NIvXpzFUAA==
-----END CERTIFICATE-----'
# AddTrust External CA Root as on 08-NOV-2012
ISSUERCERT='-----BEGIN CERTIFICATE-----
MIIE5TCCA82gAwIBAgIQB28SRoFFnCjVSNaXxA4AGzANBgkqhkiG9w0BAQUFADBv
MQswCQYDVQQGEwJTRTEUMBIGA1UEChMLQWRkVHJ1c3QgQUIxJjAkBgNVBAsTHUFk
ZFRydXN0IEV4dGVybmFsIFRUUCBOZXR3b3JrMSIwIAYDVQQDExlBZGRUcnVzdCBF
eHRlcm5hbCBDQSBSb290MB4XDTEyMDIxNjAwMDAwMFoXDTIwMDUzMDEwNDgzOFow
czELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4G
A1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQxGTAXBgNV
BAMTEFBvc2l0aXZlU1NMIENBIDIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQDo6jnjIqaqucQA0OeqZztDB71Pkuu8vgGjQK3g70QotdA6voBUF4V6a4Rs
NjbloyTi/igBkLzX3Q+5K05IdwVpr95XMLHo+xoD9jxbUx6hAUlocnPWMytDqTcy
Ug+uJ1YxMGCtyb1zLDnukNh1sCUhYHsqfwL9goUfdE+SNHNcHQCgsMDqmOK+ARRY
FygiinddUCXNmmym5QzlqyjDsiCJ8AckHpXCLsDl6ez2PRIHSD3SwyNWQezT3zVL
yOf2hgVSEEOajBd8i6q8eODwRTusgFX+KJPhChFo9FJXb/5IC1tdGmpnc5mCtJ5D
YD7HWyoSbhruyzmuwzWdqLxdsC/DAgMBAAGjggF3MIIBczAfBgNVHSMEGDAWgBSt
vZh6NLQm9/rEJlTvA73gJMtUGjAdBgNVHQ4EFgQUmeRAX2sUXj4F2d3TY1T8Yrj3
AKwwDgYDVR0PAQH/BAQDAgEGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEQYDVR0gBAow
CDAGBgRVHSAAMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwudXNlcnRydXN0
LmNvbS9BZGRUcnVzdEV4dGVybmFsQ0FSb290LmNybDCBswYIKwYBBQUHAQEEgaYw
gaMwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNlcnRydXN0LmNvbS9BZGRUcnVz
dEV4dGVybmFsQ0FSb290LnA3YzA5BggrBgEFBQcwAoYtaHR0cDovL2NydC51c2Vy
dHJ1c3QuY29tL0FkZFRydXN0VVROU0dDQ0EuY3J0MCUGCCsGAQUFBzABhhlodHRw
Oi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBBQUAA4IBAQCcNuNOrvGK
u2yXjI9LZ9Cf2ISqnyFfNaFbxCtjDei8d12nxDf9Sy2e6B1pocCEzNFti/OBy59L
dLBJKjHoN0DrH9mXoxoR1Sanbg+61b4s/bSRZNy+OxlQDXqV8wQTqbtHD4tc0azC
e3chUN1bq+70ptjUSlNrTa24yOfmUlhNQ0zCoiNPDsAgOa/fT0JbHtMJ9BgJWSrZ
6EoYvzL7+i1ki4fKWyvouAt+vhcSxwOCKa9Yr4WEXT0K3yNRw82vEL+AaXeRCk/l
uuGtm87fM04wO+mPZn+C+mv626PAcwDj1hKvTfIPWhRRH224hoFiB85ccsJP81cq
cdnUl4XmGFO3
-----END CERTIFICATE-----'


if [[ ! -f /tmp/$$.issuer.pem ]]; then
    echo "$ISSUERCERT" > /tmp/$$.issuer.pem
else
    echo "CRITICAL: cannot write issuer certificate to /tmp/$$.issuer.pem"
    exit 2
fi

if [[ ! -f /tmp/$$.certificatetocheck.pem ]]; then
    echo "$CERTTOCHECK" > /tmp/$$.certificatetocheck.pem
else
    echo "CRITICAL: cannot write certificate to /tmp/$$.certificatetocheck.pem"
    exit 2
fi

OCSPRESPONSE=$(openssl ocsp -nonce -issuer /tmp/$$.issuer.pem -cert /tmp/$$.certificatetocheck.pem -url "$OCSPURL" 2>&1)
if [[ $? -ne 0 ]]; then
    if [[ "$OCSPRESPONSE" =~ "OCSP_parse_url:error parsing url" ]]; then
        echo "CRITICAL: OCSP URL parse error."
        exit 2
    fi
    if [[ "$OCSPRESPONSE" =~ "Connection refused" ]]; then
        echo "CRITICAL: OCSP refused connection."
        exit 2
    fi
    if [[ "$OCSPRESPONSE" =~ "Code=404" ]]; then
        echo "CRITICAL: OCSP returns HTTP error 404 (Not Found)."
        exit 2
    fi
    echo -n "CRITICAL: OCSP check FAILED for OCSP: ${OCSPURL}. " 
    exit 2
fi

if [[ -f /tmp/$$.issuer.pem ]]; then
    rm /tmp/$$.issuer.pem
fi

if [[ -f /tmp/$$.certificatetocheck.pem ]]; then
    rm /tmp/$$.certificatetocheck.pem
fi

echo "$OCSPRESPONSE" | grep -q ": revoked"
if [[ $? -eq 0 ]]; then

    echo -n "CRITICAL: certificate for ${CERTCN} REVOKED by OCSP: ${OCSPURL} " 
    exit 2
fi

echo "$OCSPRESPONSE" | grep -q ": unknown"
if [[ $? -eq 0 ]]; then
    echo -n "WARNING: status of certificate for ${CERTCN} UNKNOWN by OCSP: ${OCSPURL} " 
    exit 1
fi

echo "$OCSPRESPONSE" | grep -q ": good"
if [[ $? -eq 0 ]]; then
    echo -n "OK: OCSP up and running - status of certificate for ${CERTCN} GOOD by OCSP: ${OCSPURL} " 
    exit 0
fi

echo "$OCSPRESPONSE" | grep -q "unauthorized"
if [[ $? -eq 0 ]]; then
    echo -n "WARNING: OCSP Responder Error: unauthorized (6) "  
    exit 1
fi


