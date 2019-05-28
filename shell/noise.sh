#!/bin/bash

downlink_freq="--freq=2.66G"
uplink_freq="--freq=2.54G"



for force in 70 100 80; do
   ampl= $(( (RANDOM % 10) +1 ))
   command="uhd_siggen --gaussian $uplink_freq -m $ampl"
   command="$command -g $force"
   echo "About to run command:"
   echo $command
   #$command & pidsave=$!
   #wait 30;kill $pidsave
  #timeout 30s $command
   timelimit -t10 $command
done
	

