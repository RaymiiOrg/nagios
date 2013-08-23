#!/bin/bash
# Copyright (C) 2013 - Remy van Elst

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if [[ "${BASH_VERSION:0:1}" -ne 4 ]]; then
    # Is needed for the advanced array support"
    echo "CRITICAL: Bash version 4 or higher is required."
    exit 2
fi

declare -A MASTERSOA

MASTERSERVER="10.0.2.99"
SLAVESERVERS=("10.56.2.99" "10.22.6.99")
DOMAINS=("your-int-domain.ext" "example.org" " your-other-domain.ext")

domaincount=0
for domain in ${DOMAINS[@]}; do
    MASTERSOA[$domaincount]=`dig @$MASTERSERVER +short SOA $domain | awk '{ print $3 }'`
    let domaincount++
done

errors=0
domaincount=0
for domain in ${DOMAINS[@]}; do
    for slave in ${SLAVESERVERS[@]}; do
        slavesoa=`dig @$slave +short SOA $domain | awk '{ print $3 }'`
        if [[ $slavesoa -ne ${MASTERSOA[$domaincount]} ]]; then
            echo -n "CRITICAL: DNS zone for $domain on minion $slave out of sync with master $MASTERSERVER. "
            echo -n "It is $slavesoa but it should be ${MASTERSOA[$domaincount]}.; "
            let errors++
        fi
    done
    let domaincount++
done

if [[ $errors -ne 0 ]]; then
    echo " Errors in DNS zone sync."
    exit 2
elif [[ $errors -eq 0 ]]; then
    echo "OK: All DNS zones in sync. Domains checked: ${DOMAINS[@]}. Nameservers checked: ${SLAVESERVERS[@]} against master $MASTERSERVER"
    exit 0
fi
