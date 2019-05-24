#!/bin/bash

downlink_freq="--freq=2.66G"
uplink_freq="--freq=2.54G"


'''function scrambling-noise{ 

    local command="uhd_siggen --gaussian $uplink_freq"
  
    for force in 70 100; do
	
	command="$command -g $force"
    	echo "About to run command:"
    	echo $command
    	$command
	sleep 60
   done
}'''

command="uhd_siggen --gaussian $uplink_freq"
  
for force in 70 100; do
   command="$command -g $force"
   echo "About to run command:"
   echo $command
   #$command & pidsave=$!
   #wait 30;kill $pidsave
  #timeout 30s $command
   timelimit -t30 $command
done

'''command="uhd_siggen --gaussian $uplink_freq"
force=70
while $force<; do
	force=$(($force+10))
	echo $force
	command="$command -g $force"
        echo "About to run command:"
   	echo $command
   	$command'''	

