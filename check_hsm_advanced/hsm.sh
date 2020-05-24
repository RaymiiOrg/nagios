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

# First some variables
CTC="/opt/safenet/protecttoolkit5/ptk/bin/ctcheck"
CTCOPTS="-N" # no globals
HSM_NAME=""
CHECK_TYPE=""
HSM_GREP='grep -v -e ^# -e ^$'
HSM_SED='sed s/~//g'

# Make sure we can access everything.
export CPROVDIR=/opt/safenet/protecttoolkit5/ptk
export PATH=$PATH:$CPROVDIR/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CPROVDIR/lib
export MANPATH=$MANPATH:$CPROVDIR/man


# How should I be used?
function usage() {
    cat << EOF
    usage: $0 options

    This script checks various safenet HSM things and outputs nagios style results.

    OPTIONS:
       -h      Show this message
       -t      Check type: "battery", "RAM", "datetime", "eventlog", "initialized", "hsminfo", "fminfo"
       -n      HSM name for \$ET_HSM_NETCLIENT_SERVERLIST.
       -b      ctcheck binary (default: /opt/safenet/protecttoolkit5/ptk/bin/ctcheck)

    CHECKS:
       battery          Show HSM Battery status, GOOD (ok) or LOW (crit)
       ram              HSM RAM, (ok) if <75% used, (warn) >75% <85% used, (crit) if >85% used.
       datetime         Local HSM date/time, (crit) if different from host time, host should use ntp in same timezone.
       eventlog         (ok) if eventlog not full, (crit) if eventlog full.
       initialized      (ok) if initialized, (crit) if not. Documentation states that a FALSE could mean a tampered device.
       hsminfo          always (ok), returns general HSM info, model, version, firmware and such.
       fminfo           always (ok), returns Funcrtional Module information.
EOF
exit 3
}

# DRY, nagios exit codes are quite simple..
# usage: nagios_response EXITCODE "MESSAGE"
function nagios_response() {
    if [[ ! -z ${1} ]] && [[ ! -z ${2} ]]; then
        EXIT_MESSAGE=${2}
        case ${1} in
            0)
                EXIT_CODE=0
                EXIT_CODE_VERBOSE="OK:"
                ;;
            1)
                EXIT_CODE=1
                EXIT_CODE_VERBOSE="WARNING:"
                ;;
            2)
                EXIT_CODE=2
                EXIT_CODE_VERBOSE="CRITICAL:"
                ;;
            3)
                EXIT_CODE=3
                EXIT_CODE_VERBOSE="UNKNOWN:"
                ;;
        esac

        echo -n ${EXIT_CODE_VERBOSE}
        echo -n " "
        echo "${EXIT_MESSAGE}"
        exit ${EXIT_CODE}

    else
        echo "CRITICAL: exit code unknown or wrong option provided."
        exit 2
    fi

}

# HSM Connection test
function hsm_conn_test() {
    HSM_CONN_TEST=`$CTC $CTCOPTS -n 2>&1`
    if [[ "$HSM_CONN_TEST" == "ctcheck: CM_Initialize returned 5" ]]; then
        nagios_response 3 "Could not connect to HSM ${HSM_NAME}"
    fi
}


# Output basic HSM info
function check_hsm_device_info() {
    SN=`$CTC $CTCOPTS -b serialnumber | $HSM_GREP | $HSM_SED`
    MODEL=`$CTC $CTCOPTS -b model | $HSM_GREP | $HSM_SED`
    DEV_REV=`$CTC $CTCOPTS -b devicerevision | $HSM_GREP | $HSM_SED`
    FIRMWARE_REV=`$CTC $CTCOPTS -b firmwarerevision | $HSM_GREP | $HSM_SED`
    DATEOFMAN=`$CTC $CTCOPTS -b dateofmanufacture | $HSM_GREP | $HSM_SED`
    EVENT_LOG_COUNT=`$CTC $CTCOPTS -b eventlogcount | $HSM_GREP | $HSM_SED`
    SLOT_COUNT=`$CTC $CTCOPTS -b slotcount | $HSM_GREP | $HSM_SED`
    PTKC_REV=`$CTC $CTCOPTS -b ptkcrevision | $HSM_GREP | $HSM_SED`
    DEV_BATCH=`$CTC $CTCOPTS -b batch | $HSM_GREP | $HSM_SED`
    SEC_MODE=`$CTC $CTCOPTS -b securitymode | $HSM_GREP | $HSM_SED`
    TRANS_MODE=`$CTC $CTCOPTS -b transportmode | $HSM_GREP | $HSM_SED`
    nagios_response 0 "HSM: ${HSM_NAME}; Serial Number: ${SN}; Model: ${MODEL}; Device Revision: ${DEV_REV}; Firmware Revision: ${FIRMWARE_REV}; Manufacturing Date: ${DATEOFMAN}; Device Batch: ${DEV_BATCH}; PTKC Revision: ${PTKC_REV}; Slot Count: ${SLOT_COUNT}; Security Mode: ${SEC_MODE}; Transport Mode: ${TRANS_MODE}; Event Log Count: ${EVENT_LOG_COUNT}."
}

# Output Functional Module Information
function check_hsm_fm_info {
    FUNC_MODL_SUPP=`$CTC $CTCOPTS -b fmsupport | $HSM_GREP | $HSM_SED`
    FUNC_MODL_LABEL=`$CTC $CTCOPTS -b fmlabel | $HSM_GREP | $HSM_SED`
    FUNC_MODL_VERSION=`$CTC $CTCOPTS -b fmversion | $HSM_GREP | $HSM_SED`
    FUNC_MODL_MANF=`$CTC $CTCOPTS -b fmmanufacturer | $HSM_GREP | $HSM_SED`
    FUNC_MODL_BT=`$CTC $CTCOPTS -b fmbuildtime | $HSM_GREP | $HSM_SED`
    FUNC_MODL_ROM=`$CTC $CTCOPTS -b fmromsize | $HSM_GREP | $HSM_SED`
    FUNC_MODL_RAM=`$CTC $CTCOPTS -b fmramsize | $HSM_GREP | $HSM_SED`
    nagios_response 0 "HSM: ${HSM_NAME}; FM Support: ${FUNC_MODL_SUPP}; FM Label: ${FUNC_MODL_LABEL}; FM Version: ${FUNC_MODL_VERSION}; FM Manufacter: ${FUNC_MODL_MANF}; FM Build DateTime: ${FUNC_MODL_BT}; FM ROM Space: ${FUNC_MODL_ROM}; FM RAM Space: ${FUNC_MODL_RAM}."
}

function check_hsm_battery() {
    battery_command=`$CTC $CTCOPTS -b batterystatus | $HSM_GREP | $HSM_SED`
    if [[ $battery_command == "GOOD" ]]; then
        nagios_response 0 "Battery status is good for HSM: ${HSM_NAME}"
    elif [[ $battery_command == "LOW" ]]; then
        nagios_response 2 "Battery status is LOW for HSM: ${HSM_NAME}"
    else 
        nagios_response 3 "Battery status is unknown for HSM: ${HSM_NAME}"
    fi
}

function check_hsm_initialized() {
    hsm_initialized_command=`$CTC $CTCOPTS -b deviceinitialised | $HSM_GREP | $HSM_SED`
    if [[ "$hsm_initialized_command" == "TRUE" ]]; then
        nagios_response 0 "HSM: ${HSM_NAME} is initialized. All is well."
    elif [[ "$hsm_initialized_command" == "TRUE" ]]; then
        nagios_response 2 "HSM: ${HSM_NAME} reports not initialized. Device might be TAMPERED."
    else
        nagios_response 3 "HSM ${HSM_NAME} initialization status unknown."
    fi
}

function check_hsm_eventlog() {
    EVENT_LOG_COUNT=`$CTC $CTCOPTS -b eventlogcount| $HSM_GREP | $HSM_SED`
    nagios_response 0 "HSM: ${HSM_NAME} Event Log Count: ${EVENT_LOG_COUNT}"
}

function check_hsm_ram() {
    FREE_RAM=`$CTC $CTCOPTS -b freepublicmemory | $HSM_GREP | $HSM_SED` 
    TOTAL_RAM=`$CTC $CTCOPTS -b totalpublicmemory | $HSM_GREP | $HSM_SED`
    USED_RAM=$(( ${TOTAL_RAM} - ${FREE_RAM} ))
    TOTAL_PERC=$(( ${TOTAL_RAM} / 100 ))
    USED_PERC=$(( ${USED_RAM} / ${TOTAL_PERC} ))

    OK=50
    CRIT=85

    if [[ ${USED_PERC} < ${OK} ]]; then
        nagios_response 0 "RAM Usage OK: ${USED_PERC}% used, ( ${TOTAL_RAM} total). HSM: ${HSM_NAME}.";
    elif [[ ${USED_PERC} > ${OK} ]] && [[ ${USED_PERC} < ${CRIT} ]]; then
        nagios_response 1 "RAM Usage WARN: ${USED_PERC}% used, ( ${TOTAL_RAM} total). HSM: ${HSM_NAME}.";
    elif [[ ${USED_PERC} > ${CRIT} ]]; then
        nagios_response 2 "RAM Usage CRIT: ${USED_PERC}% used, ( ${TOTAL_RAM} total). HSM: ${HSM_NAME}.";
    else
        nagios_response 3 "RAM Usage unknown for HSM ${HSM_NAME}";
    fi
}

function check_hsm_datetime() {

    LOCAL_TIME=`date +%d/%m/%Y\ %H:%M`
    HSM_FULL_TIME=`$CTC $CTCOPTS -b clocklocal | $HSM_GREP | $HSM_SED`
    HSM_TIME=${HSM_FULL_TIME:0:16}

    if [[ ${LOCAL_TIME} == ${HSM_TIME} ]]; then
        nagios_response 0 "HSM: ${HSM_NAME} time is the same as local time: ${LOCAL_TIME}."
    else
        nagios_response 2 "HSM: ${HSM_NAME} time is NOT CORRECT. It is ${HSM_TIME} but it should be ${LOCAL_TIME}."
    fi

}


# option parsing
while getopts “ht:b:n:” OPTION; do
    case ${OPTION} in
        h)
            usage
            ;;
        t)
            CHECK_TYPE=${OPTARG}
            ;;
        b)
            U_CTC=${OPTARG}
            ;;
        n)
            HSM_NAME=${OPTARG}
            ;;
        ?)
            usage
            ;;
    esac
done

## Do we have a binary overrride?
if [[ ! -z ${U_CTC} ]] && [[ -f ${U_CTC} ]]; then
    CTC=${U_CTC}
fi

## Do we have all required options?
if [[ -z ${CHECK_TYPE} ]] || [[ -z ${CTC} ]] || [[ -z ${HSM_NAME} ]]; then
     usage
fi

# Export HSM list
export ET_HSM_NETCLIENT_SERVERLIST=${HSM_NAME}
ET_HSM_NETCLIENT_SERVERLIST=${HSM_NAME}

# Does the ctcheck exist?
if [[ ! -f ${CTC} ]]; then
    nagios_response 2 "CTCHECK binary not available: ${CTC}."
fi

hsm_conn_test

case ${CHECK_TYPE} in
    "battery")
        check_hsm_battery;
        ;;
    "ram")
        check_hsm_ram;
        ;;
    "hsminfo")
        check_hsm_device_info;
        ;;
    "fminfo")
        check_hsm_fm_info;
        ;;
    "datetime")
        check_hsm_datetime;
        ;;
    "initialized")
        check_hsm_initialized;
        ;;
    "eventlog")
        check_hsm_eventlog;
        ;;
    ?)
        echo "Check type not supported."
        usage
        ;;
esac

