#!/bin/bash
# Very simple nagios check for apt updates
# License: GPLv3
# Author: Remy van Elst - https://raymii.org
sudo -n $(which apt-get) -qq update > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo "UNKNOWN: Could not apt-get update. Please add sudo rule for $(whoami) user:"
    echo "# visudo -f /etc/sudoers.d/10_nagios_apt"
    echo "$(whoami) ALL=(ALL) NOPASSWD: $(which apt-get) -qq update"
    exit 4
fi

APT_UPDATE_TEXT="$($(which apt-get) -qq --just-print upgrade | awk '/Inst/ {print $2"\t"$3"\t -> "$4}' | sort -u | sed -e 's/\[//g' -e 's/\]//g' -e 's/(//g' -e 's/)//g' | column -t)"
APT_UPDATE_NO=$(echo -n "${APT_UPDATE_TEXT}" | wc -l)
if [[ "${APT_UPDATE_NO}" -ge 1 ]]; then
    echo "WARNING: ${APT_UPDATE_NO} updates available."
    echo "${APT_UPDATE_TEXT}"
    exit 1
else
    echo "OK: ${APT_UPDATE_NO} updates available."
    exit 0
fi
