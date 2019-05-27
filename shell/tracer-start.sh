#!/bin/bash

function start-tracer() {
    echo "starting the T tracer"
    cd [ -d /root/openairinterface5g/common/utils/T/tracer]
    run-in-log build-tracer.log ./textlog -no-gui -ON -d ../T_messages.txt -ip 192.168.3.23
}
