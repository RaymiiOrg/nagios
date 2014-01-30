#!/bin/bash
# Copyright (C) 2014 Remy van Elst <raymii.org>

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


if [[ -r "/etc/ossec-init.conf" ]]; then
	source /etc/ossec-init.conf
fi

if [[ -z "${DIRECTORY}" ]]; then
	echo "UNKNOWN: Cannot determine OSSEC directory. OSSEC may not be installed"
	exit 3
elif [[ "${TYPE}" = "agent" ]]; then
	echo "UNKNOWN: Target is not an OSSEC server"
	exit 3
fi

AGENTS="$(sudo -n ${DIRECTORY}/bin/list_agents -n)"
if [[ ${?} != "0" ]]; then
	echo "UNKNOWN: Unable to execute list_agents. Is sudo configured?"
	echo "Add the following to /etc/sudoers USING VISUDO!:"
	echo -e "$(whoami)\tALL=NOPASSWD:\t${DIRECTORY}/bin/list_agents -n"
	exit 3
fi

INACTIVE_AGENTS="$(sudo -n ${DIRECTORY}/bin/list_agents -n | grep -c -- "is not active")"
if [[ "${INACTIVE_AGENTS}" != "0" ]]; then
	echo "CRITICAL: ${INACTIVE_AGENTS} OSSEC Agents not connected"
	echo "${AGENTS}" | awk '{ printf $1", "}'
	exit 2
else
	echo "OK: All OSSEC Agents are connected"
	exit 0
fi