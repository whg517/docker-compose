#!/bin/bash

if [ -z $1 ] 
then
   /usr/bin/proxy sps -S socks -T tcp -P $SOCKS5_ADDR -t tcp -p $SPS_ADDR --max-conns-rate $MAX_CONNECTIONS
else
   /usr/bin/proxy $@
fi