#!/bin/bash
#
# Copyright (C) 2014 Remy van Elst; https://raymii.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

DOMAIN="$1"
NAMESERVER="$2"
MONITOR_HOST="$3"
CONTACT_GROUPS="$4"

usage() {
echo "Usage: ./${0} DOMAIN NAMESERVER NAGIOS_MONITOR_HOST CONTACT_GROUPS"
echo "This script converts a dig based zone transfer to a nagios check http config"
echo "Example: ./${0} example.org 10.23.0.6 localhost admins"
echo "The command definition used is:"
echo "define command {"
echo "    command_name    check_http_with_url"
echo "    command_line    /usr/lib/nagios/plugins/check_http -N -t 30 -H $ARG1$ -u $ARG2$ -w $ARG3$ -c $ARG4$"
echo "}"
exit 1
}

[[ -z "${1}" || -z "${2}" || -z "${3}" || -z "${4}" ]] && usage ;

DOMAINS="$(dig AXFR @${NAMESERVER} ${DOMAIN} | grep 'A\|CNAME' | awk {'print substr($1, 1, length($1) - 1)'} | sort -u | grep '[[:alpha:]]')"

while read DOMAIN; do
    echo "define service {"
    echo "    use                             generic-service"
    echo "    host_name                       ${MONITOR_HOST}"
    echo "    service_description             http://${DOMAIN}"
    echo "    contact_groups                  ${CONTACT_GROUPS}"
    echo "    check_command                   check_http_with_url!${DOMAIN}!/!3!5"
    echo "}"
    echo ""
done <<< "${DOMAINS}"
