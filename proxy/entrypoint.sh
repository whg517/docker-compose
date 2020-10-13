#!/bin/bash

/usr/bin/proxy @/etc/proxy/configfile.txt
echo "go proxy started."

$@
