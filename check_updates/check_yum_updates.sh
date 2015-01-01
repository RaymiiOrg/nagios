#!/bin/bash
# Very simple nagios check for yum updates
# License: GPLv3
# Author: Remy van Elst - https://raymii.org
sudo -n $(which yum) -q --exclude="kernel*" check-update > /dev/null 2>&1
if [[ $? != 0 ]]; then
    echo "UNKNOWN: Could not yum update. Please add sudo rule for $(whoami) user."
    echo "# visudo -f /etc/sudoers.d/10_nagios_yum"
    echo "$(whoami) ALL=(ALL) NOPASSWD: $(which yum) -q --exclude="kernel*" check-update "
    exit 4
fi

YUM_UPDATE_TEXT="$($(which yum) check-update 2>&1 | grep -v -e "^$" -e "kernel" -e "Obsoleting" -e "Excluding" -e "Finished" -e "plugins:" -e "mirror" -e "epel-source" -e "epel-debuginfo" -e "no version information" -e "base:" -e "epel:" -e "rpmforge" -e "remi" -e "extra:" -e "updates:" -e "extras" | awk '{print $1"\t -> "$2}' | column -t)"
YUM_UPDATE_NO=$(echo -n "${YUM_UPDATE_TEXT}" | wc -l)
if [[ "${YUM_UPDATE_NO}" -ge 1 ]]; then
    echo "WARNING: ${YUM_UPDATE_NO} updates available."
    echo "${YUM_UPDATE_TEXT}"
    exit 1
else
    echo "OK: ${YUM_UPDATE_NO} updates available."
    exit 0
fi
