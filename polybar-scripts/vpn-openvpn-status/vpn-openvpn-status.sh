#!/bin/env bash
IFS=$'\n'
printf "VPNs: " && echo $(for process in $(pgrep -a openvpn$); do echo $process | grep -Po '(?<=--remote\ )(\S*)|(?<=--config\ /etc/openvpn/)([A-Za-z0-9_\-]*)(?=\.conf|\.ovpn)|(?<=--config\ )([A-Za-z0-9_\-]*)(?=\.conf|\.ovpn)'; done)
unset IFS
