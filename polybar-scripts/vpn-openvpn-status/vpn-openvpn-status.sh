#!/bin/env bash
IFS=$'\n'
if [[ ! "$1" =~ "-noprefix" ]]; then
    printf "VPNs: "
fi
for process in $(pgrep -a openvpn$); do
    echo $process | grep -Po '(?<=--remote\ )(\S*)|(?<=--config\ /etc/openvpn/)([A-Za-z0-9_\-]*)(?=\.conf|\.ovpn)|(?<=--config\ )([A-Za-z0-9_\-]*)(?=\.conf|\.ovpn)';
done
unset IFS
