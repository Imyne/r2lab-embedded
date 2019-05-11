#!/bin/bash

apt update

apt install iperf3 -y

usb-reset()

ifup enx0c5b8f279a64


address_dest=$1
interface_to_bind="enx0c5b8f279a64"
port=$2

iperf3 -c $1 -B $interface_to_bind -u -p $2



   
