#!/bin/bash


[ -z "$_sourced_nodes" ] && source $(dirname $(readlink -f $BASH_SOURCE))/nodes.sh

doc-nodes-sep "#################### For managing an OAI enodeb"

[ -z "$_sourced_oai_common" ] && source $(dirname $(readlink -f $BASH_SOURCE))/oai-common.sh


doc-nodes start-tracer "start tracer on node 19 yooliiiii"
function start-tracer() {
    echo "starting the T tracer"
    cd ..
    cd /root/openairinterface5g/common/utils/T/tracer
    make
    ./textlog -no-gui -on ENB_PHY_ULSCH_UE_DCI -on ENB_PHY_ULSCH_UE_NO_DCI_RETRANSMISSION -on ENB_PHY_UL_CHANNEL_ESTIMATE -on ENB_PHY_PUSCH_IQ -on ENB_PHY_PUCCH_1_ENERGY -on ENB_PHY_PHICH -on ENB_MAC_UE_UL_SCHEDULE -on ENB_MAC_UE_UL_PDU -on ENB_RLC_UL -on LEGACY_UDP__INFO -on LEGACY_RLC_INFO -on LEGACY_MAC_INFO -on LEGACY_MAC_DEBUG -on LEGACY_PHY_INFO -on LEGACY_PHY_DEBUG -on UE_PHY_MEAS -d ../T_messages.txt -ip 192.168.3.23 >& tracelog.log

}


########################################
define-main "$0" "$BASH_SOURCE"
main "$@"
