#!/bin/bash

downlink_freq="--freq=2.66G"
uplink_freq="--freq=2.54G"

gains=($(shuf -i 20-90 -n 15))
echo "${gains[@]}"

command="uhd_siggen --gaussian"
for force in "${gains[@]}"; do
   #ampl= $(( (RANDOM % 10) +1 ))
   command="$command $uplink_freq -m $(( (RANDOM % 15) +1 )) -g $force"
  # command="$command -g $force"
   echo "About to run command:"
   echo $command
   #$command & pidsave=$!
   #wait 30;kill $pidsave
  #timeout 30s $command
   timelimit -t10 $command
done
	

