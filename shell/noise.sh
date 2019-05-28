#!/bin/bash

downlink_freq="--freq=2.66G"
uplink_freq="--freq=2.54G"

gains=($(shuf -i 10-90 -n 15))
echo "${gains[@]}"

for force in "${gains[@]}"; do
   #ampl= $(( (RANDOM % 10) +1 ))
   command="uhd_siggen --gaussian $uplink_freq -m $(( (RANDOM % 15) +1 ))"

   command="$command -g $force"
   echo "About to run command:"
   echo $command
   #$command & pidsave=$!
   #wait 30;kill $pidsave
  #timeout 30s $command
   timelimit -t10 $command
done
	

