#!/bin/bash

apt update

apt install iperf3 -y

ifup enx0c5b8f279a64


address_dest=$1
interface_to_bind="enx0c5b8f279a64"
bandwidth=$2
port=$3
time=$4

iperf3 -c $1 -B $interface_to_bind -u -b $2 -p $3 -t $4



   
