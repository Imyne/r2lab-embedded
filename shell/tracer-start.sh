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
    ./textlog -no-gui -ON -d ../T_messages.txt -ip 192.168.3.23 >& tracelog.log
    #./textlog -no-gui -on ENB_PHY_DLSCH_UE_DCI -on ENB_PHY_ULSCH_UE_DCI -d ../T_messages.txt -ip 192.168.3.23 >& tracelog.log

}


########################################
define-main "$0" "$BASH_SOURCE"
main "$@"
