#!/bin/bash

OVPN=${OVPN:-$HOME/.sesame/sest/sest.ovpn}
NAME=${NAME:-sest}
NSNET="10.200.201.0"
NSGW=${NSNET::-1}2

echo "Starting VPN"
~/myvpn.sh up $NAME $NSNET
~/myvpn.sh start_vpn $NAME $OVPN
~/myvpn.sh run $NAME vtapia "sudo iptables -t nat -A POSTROUTING -s ${NSNET}/24 -o tap0 -j MASQUERADE"
~/myvpn.sh run $NAME vtapia "sudo sysctl -q net.ipv4.ip_forward=1"
sudo ip route add 192.168.88.0/24 via $NSGW
# sudo systemctl stop ssh
