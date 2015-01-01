#!/bin/bash
# Very simple nagios check for pacman updates
# License: GPLv3
# Author: Remy van Elst - https://raymii.org
sudo -n $(which pacman) -Sy > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo "UNKNOWN: Could not update pacman db. Please add sudo rule for $(whoami) user."
    echo "# visudo -f /etc/sudoers.d/10_nagios_pacman"
    echo "$(whoami) ALL=(ALL) NOPASSWD: $(which pacman) -Sy"
    exit 4
fi

PACMAN_UPDATE_TEXT="$($(which pacman) -Qu)"
PACMAN_UPDATE_NO=$(echo -n "${PACMAN_UPDATE_TEXT}" | wc -l)
if [[ "${PACMAN_UPDATE_NO}" -ge 1 ]]; then
    echo "WARNING: ${PACMAN_UPDATE_NO} updates available."
    echo "${PACMAN_UPDATE_TEXT}"
    exit 1
else
    echo "OK: ${PACMAN_UPDATE_NO} updates available."
    exit 0
fi
