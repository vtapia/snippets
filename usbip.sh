#!/bin/bash
USBIPPATH=$(ls -dvr /usr/lib/linux-tools/* | head -1)

if [ ! -d "${USBIPPATH}" ]; then
  echo "Please install the linux-tools package suitable for your kernel"
  exit 1
fi

echo "- Loading modules"
modprobe vhci-hcd
modprobe usbip-core
modprobe usbip-host

echo "- Starting daemon"
${USBIPPATH}/usbipd -D

echo "- Available devices"
${USBIPPATH}/usbip list -l
BUSID=$(${USBIPPATH}/usbip list -l | grep '05ca:0448' | grep busid | awk '{print $3}')

echo "- Binding printer (${BUSID})"
${USBIPPATH}/usbip bind -b ${BUSID}

echo "- Test attach/detach"
${USBIPPATH}/usbip --debug attach -r 127.0.0.1 -b ${BUSID}
sleep 1
${USBIPPATH}/usbip --debug detach -p 0
