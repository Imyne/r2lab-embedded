#!/bin/bash

downlink_freq="--freq=2.66G"
uplink_freq="--freq=2.54G"



#doc-nodes 'scrambling-noise' "shortcuts for scrambling my demo; "
scrambling-noise() { 

    local command="uhd_siggen --gaussian $uplink_freq"
  
    for force in 70 80 100; do
	
	command="$command -g $force"
    	echo "About to run command:"
    	echo $command
    	$command
	sleep 60
   done
}

   
