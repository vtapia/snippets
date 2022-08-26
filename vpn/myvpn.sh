#!/bin/bash -x
#
# Based on https://schnouki.net/posts/2014/12/12/openvpn-for-a-single-application-on-linux/
#
# Usage example:
# $ ./my-vpn.sh up NSNAME NSNET
# $ ./my-vpn.sh start_vpn NSNAME VPNCONF
# $ ./my-vpn.sh run NSNAME USERNAME COMMAND


# in case you want to get rid of sudo
# if [[ $UID != 0 ]]; then
#     echo "This must be run as root."
#     exit 1
# fi

NIC=$(ip r | grep default | awk '{print $5}')
NETDEV=$(ip r | grep default |awk '{print $5}')
LOCALNET=$(ip -o -4 address show dev ${NIC}|awk '{print $4}')
NAMESERVER=8.8.8.8

my_ping() {
  local dest="${1:-www.google.com}"
  local count="${2:-1}"
  sudo ip netns exec $NAME ping -c $count $dest
}

iface_up() {
    NSGWINT=${NSNET::-1}1 
    NSGWEXT=${NSNET::-1}2
    sudo ip netns add $NAME ; sleep 1

    sudo ip netns exec $NAME ip addr add 127.0.0.1/8 dev lo ; sleep 1
    sudo ip netns exec $NAME ip link set lo up ; sleep 1

    sudo ip link add ${NAME}0 type veth peer name ${NAME}1 ; sleep 1
    sudo ip link set ${NAME}0 up ; sleep 1
    sudo ip link set ${NAME}1 netns $NAME up ; sleep 1

    sudo ip addr add $NSGWINT/24 dev ${NAME}0 ; sleep 1
    sudo ip netns exec $NAME ip addr add $NSGWEXT/24 dev ${NAME}1 ; sleep 1
    sudo ip netns exec $NAME ip route add default via $NSGWINT dev ${NAME}1 ; sleep 1

    sudo iptables -A INPUT -i ${NAME}0 -s $NSNET/24 -m state --state ESTABLISHED,RELATED -m comment --comment ${NAME}VPN -j ACCEPT
    sudo iptables -A INPUT \! -i ${NAME}0 -s $NSNET/24 -m comment --comment ${NAME}VPN -j DROP ; sleep 1
    sudo iptables -t nat -A POSTROUTING -s $NSNET/24 ! -d $LOCALNET -o $NETDEV -m comment --comment ${NAME}VPN -j MASQUERADE ; sleep 1

    sudo sysctl -q net.ipv4.ip_forward=1 ; sleep 1

    sudo mkdir -p /etc/netns/$NAME
    echo -e "nameserver $NAMESERVER" | sudo tee /etc/netns/$NAME/resolv.conf ; sleep 1
    my_ping
}

iface_down() {
    sudo rm -rf /etc/netns/$NAME

    # sudo sysctl -q net.ipv4.ip_forward=0

    sudo iptables-save | grep -v ${NAME}VPN | sudo iptables-restore

    sudo ip link del ${NAME}0
    sudo ip netns delete $NAME
}

run() {
    shift
    exec sudo ip netns exec $NAME "$@"
}

start_vpn() {
    pushd $(dirname $OVPN)
    sudo ip netns exec $NAME openvpn --config $OVPN --log $NAME.vpn.log &
    popd
    until sudo ip netns exec $NAME ip a show dev tun0 up || sudo ip netns exec $NAME ip a show dev tap0 up; do
        sleep .5
    done
}

stop_vpn() {
  sudo ip netns exec $NAME killall -9 openvpn
  sudo ip netns exec $NAME ip r
}

case "$1" in
    up)
	NAME=$2
	NSNET=$3
        iface_up ;;
    down)
	NAME=$2
        iface_down ;;
    start_vpn)
	NAME=$2
	OVPN=$3
      start_vpn ;;
    stop_vpn)
	NAME=$2
      stop_vpn ;;
    run)
        shift
	NAME=$1
	shift
        USER=$1
        shift
        sudo ip netns exec $NAME sudo -u $USER $@
        ;;
    ping)
      shift
      my_ping $1 $2
      ;;
    *)
        echo "Syntax: $0 up|down|start_vpn|stop_vpn NSNAME"
        echo "Also: $0 run NSNAME USER CMD"
        exit 1
        ;;
esac
