#!/bin/bash

source $(dirname $(readlink -f $BASH_SOURCE))/nodes.sh

doc-nodes-sep "#################### For managing a mosaic OAI UE"

source $(dirname $(readlink -f $BASH_SOURCE))/mosaic-common.sh

### frontend:
# image: install stuff on top of a basic ubuntu image
# warm-up: make sure the USB is there, and similar
# configure: do at least once after restoring an image
#
# start: start services
# stop:
# status
#
# journal: wrapper around journalctl for the 3 bundled services
# config-dir: echo's the configuration directory
# inspect-config-changes: show everything changed from the snap configs

### to test locally (adjust slicename if needed)
# apssh -g mosaic_oai@faraday.inria.fr -t root@fit01 -i nodes.sh -i r2labutils.sh -i mosaic-common.sh -s mosaic-oai-ue.sh image


mosaic_role="oai-ue"
mosaic_long="OAI User Equipment"


###### imaging
doc-nodes image "frontend for rebuilding this image"
function image() {
    dependencies-for-oai-ue
    install-uhd-images
    install-oai-ue
    mosaic-as-oai-ue
}

function dependencies-for-oai-ue() {
    git-pull-r2lab
    apt-get update
    apt-get install -y emacs
}

function install-uhd-images() {
    apt-get install -y uhd-host
    /usr/lib/uhd/utils/uhd_images_downloader.py >& /root/uhd_images_downloaded.log
}

function install-oai-ue() {
    -snap-install oai-ue
    oai-ue.stop-all
}


###### configuring
# nrb business : see oai-enb.sh for details

doc-nodes config-dir "echo the location of the configuration dir"
function config-dir() {
    (cd /var/snap/oai-ran/current; pwd -P)
}

doc-nodes inspect-config-changes "show all changes done by configure"
function inspect-config-changes() {
    -inspect-config-changes $(config-dir);
}


doc-nodes configure "configure RAN, i.e. tweaks e-nodeB config file - see --help"
function configure() {
    local nrb=50
    local USAGE="Usage: $FUNCNAME [options] cn-id
  options:
    -b nrb: sets NRB - default is $nrb"
    OPTIND=1
    while getopts "b:" opt; do
        case $opt in
            b) nrb=$OPTARG;;
            *) echo -e "$USAGE"; return 1;;
        esac
    done
    shift $((OPTIND-1))

    [[ -z "$@" ]] && { echo -e "$USAGE"; return 1; }
    local cn_id=$1; shift
    [[ -n "$@" ]] && { echo -e "$USAGE"; return 1; }

    local r2lab_id=$(r2lab-id -s)
    local enbconf=$(oai-ran.enb-conf-get)

    echo "Configuring RAN on node $r2lab_id for CN on node $cn_id and nrb=$nrb"
    case $nrb in
	25) refSignalPower=-24;;
	50) refSignalPower=-27;;
        *) echo -e "Bad N_RB_DL value $nrb"; return 1;;
    esac

# The good command for 25: ./lte-uesoftmodem.Rel14 -C 2660000000 -r 25 --ue-scan-carrier --ue-rxgain 110 --ue-txgain 15 --ue-max-power 0

    -sed-configurator $enbconf << EOF
s|mnc\s*=\s*[0-9][0-9]*|mnc = 95|
s|downlink_frequency\s*=.*;|downlink_frequency = 2660000000L;|
s|N_RB_DL\s*=.*|N_RB_DL = ${nrb};|
s|tx_gain\s*=.*;|tx_gain = 100;|
s|rx_gain\s*=.*;|rx_gain = 125;|
s|pdsch_referenceSignalPower\s*=.*;|pdsch_referenceSignalPower = ${refSignalPower};|
s|pusch_p0_Nominal\s*=.*;|pusch_p0_Nominal = -90;|
s|pucch_p0_Nominal\s*=.*;|pucch_p0_Nominal = -96;|
s|\(mme_ip_address.*ipv4.*=\).*|\1 "192.168.${mosaic_subnet}.${cn_id}";|
s|ENB_INTERFACE_NAME_FOR_S1_MME.*=.*"[^"]*";|ENB_INTERFACE_NAME_FOR_S1_MME = "${mosaic_ifname}";|
s|ENB_IPV4_ADDRESS_FOR_S1_MME.*=.*"[^"]*";|ENB_IPV4_ADDRESS_FOR_S1_MME = "192.168.${mosaic_subnet}.${r2lab_id}/24";|
s|ENB_INTERFACE_NAME_FOR_S1U.*=.*"[^"]*";|ENB_INTERFACE_NAME_FOR_S1U = "${mosaic_ifname}";|
s|ENB_IPV4_ADDRESS_FOR_S1U.*=.*"[^"]*";|ENB_IPV4_ADDRESS_FOR_S1U = "192.168.${mosaic_subnet}.${r2lab_id}/24";|
s|ENB_IPV4_ADDRESS_FOR_X2C.*=.*"[^"]*";|ENB_IPV4_ADDRESS_FOR_X2C = "192.168.${mosaic_subnet}.${r2lab_id}/24";|
EOF

}


###### running

doc-nodes wait-usrp "Wait until a USRP is ready - optional timeout in seconds"
function wait-usrp() {
    timeout="$1"; shift
    [ -z "$timeout" ] && timeout=
    counter=1
    while true; do
        if uhd_find_devices >& /dev/null; then
            uhd_usrp_probe >& /dev/null && return 0
        fi
        counter=$(($counter + 1))
        [ -z "$timeout" ] && continue
        if [ "$counter" -ge $timeout ] ; then
            echo "Could not find a UHD device after $timeout seconds"
            return 1
        fi
    done
}

doc-nodes node-has-b210 "Check if a USRP B210 is attached to the node"
function node-has-b210() {
    type uhd_find_devices >& /dev/null || {
        echo "you need to install uhd_find_devices"; return 1;}
    uhd_find_devices 2>&1 | grep -q B210
}

doc-nodes node-has-limesdr "Check if a LimeSDR is attached to the node"
function node-has-limesdr() {
    ls /usr/local/bin/LimeUtil >& /dev/null || {
        echo "you need to install LimeUtil"; return 1;}
    [ -n "$(/usr/local/bin/LimeUtil --find)" ]
}

doc-nodes warm-up "Prepare SDR board (b210 or lime) for running an OAI UE - see --help"
function warm-up() {
    local USAGE="Usage: $FUNCNAME [-u]
  options:
    -u: causes the USB to be reset"

    local reset=""
    OPTIND=1
    while getopts "u" opt -u; do
        case $opt in
            u) reset=true ;;
            *) echo -e "$USAGE"; return 1;;
        esac
    done
    shift $((OPTIND-1))

    [[ -n "$@" ]] && { echo -e "$USAGE"; return 1; }

    # that's the best moment to do that
    echo "Checking interface is up : $(turn-on-data)"

    # stopping OAI UE service in case of a lingering instance
    echo -n "OAI UE service ... "
    echo -n "stopping ... "
    stop > /dev/null
    echo -n "status ... "
    status
    echo

    echo -n "Warming up RAN ... "
    # focusing on b210 for this first version
    if [ -n "$reset" ]; then
        echo -n "USB off (reset requested) ... "
        usb-off >& /dev/null
    fi
    # this is required b/c otherwise node-has-b210 won't find anything
    echo -n "USB on ... "
    usb-on >& /dev/null
    delay=3
    echo -n "Sleeping $delay "
    sleep $delay
    echo Done
    echo ""

    if node-has-b210; then
        if [ -z "$reset" ]; then
            echo "B210 left alone (reset not requested)"
        else
            uhd_find_devices >& /dev/null
            echo "Loading b200 image..."
            # this was an attempt at becoming ahead of ourselves
            # by pre-loading the right OAI image at this earlier point
            # it's not clear that it is helping, as enb seems to
            # unconditionnally load the same stuff again, no matter what
            uhd_image_loader --args="type=b200" \
             --fw-path /snap/oai-ran/current/uhd_images/usrp_b200_fw.hex \
             --fpga-path /snap/oai-ran/current/uhd_images/usrp_b200_fpga.bin || {
                echo "WARNING: USRP B210 board could not be loaded - probably need a RESET"
                return 1
    	    }
            echo "B210 ready"
        fi
    elif node-has-limesdr; then
	    # Load firmware on the LimeSDR device
	    echo "Running LimeUtil --update"
	    LimeUtil --update
        [ -n "$reset" ] && { echo Resetting USB; usb-reset; } || echo "SKIPPING USB reset"
    else
	    echo "WARNING: Neither B210 nor LimeSDR device attached to the eNB node!"
	    return 1
    fi
}

doc-nodes start "Start OAI UE; option -x means graphical - requires X11-enabled ssh session"
function start() {
    local USAGE="Usage: $FUNCNAME [options]
  options:
    -x: start in graphical mode (or -o for compat)"

    local graphical=""
    local oai_ue_opt="" 

    OPTIND=1
    while getopts "xo" opt; do
        case $opt in
            x|o)
                graphical=true;;
            *)
                echo -e "$USAGE"; return 1;;
        esac
    done
    shift $((OPTIND-1))

    [[ -n "$@" ]] && { echo -e "$USAGE"; return 1; }
    echo "Checking interface is up : $(turn-on-data)"

    echo "Show r2lab conf before running the eNB"
    oai-ue.conf-show

    if [ -n "$graphical" ]; then
        echo "e-nodeB with X11 graphical output not yet implemented - running in background instead for now"
        oai_ue_opt+=" -d"
    fi
    oai-ue.start $oai_ue_opt
}

doc-nodes stop "Stop OAI UE service(s)"
function stop() {
    oai-ue.stop
}

doc-nodes status "Displays status of OAI UE service(s)"
function status() {
    oai-ue.status
}

doc-nodes journal "Wrapper around journalctl about OAI UE service(s) - use with -f to follow up"
function journal() {
    units="snap.oai-ran.enbd.service"
    jopts=""
    for unit in $units; do jopts="$jopts --unit $unit"; done
    journalctl $jopts "$@"
}

doc-nodes configure-directory "cd into configuration directory for RAN service(s)"
function configure-directory() {
    local conf_dir=$(dirname $(oai-ran.enb-conf-get))
    cd $conf_dir
}

########################################
define-main "$0" "$BASH_SOURCE"
main "$@"