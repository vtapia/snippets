#!/bin/bash

configfile=/etc/vfio-pci1.cfg
hdd=/home/ubuntu/devel/passthrough/vm1/win.img
cd=/home/ubuntu/devel/passthrough/vm1/win7.iso

vfiobind() {
    dev="$1"
        vendor=$(cat /sys/bus/pci/devices/$dev/vendor)
        device=$(cat /sys/bus/pci/devices/$dev/device)
        if [ -e /sys/bus/pci/devices/$dev/driver ]; then
                echo $dev > /sys/bus/pci/devices/$dev/driver/unbind
        fi
        echo $vendor $device > /sys/bus/pci/drivers/vfio-pci/new_id

}

modprobe vfio-pci

cat $configfile | while read line;do
    echo $line | grep ^# >/dev/null 2>&1 && continue
        vfiobind $line
done

qemu-system-x86_64 -enable-kvm -m 16384 -device virtio-balloon -cpu host,kvm=off -smp 4,sockets=1,cores=4,threads=1 \
-pflash /usr/share/ovmf/OVMF.fd \
-rtc base=localtime,clock=host \
-device vfio-pci,host=01:00.0,multifunction=on,x-vga=on \
-device vfio-pci,host=01:00.1 \
-device virtio-scsi-pci,id=scsi \
-drive file=./Win10Ent_14393.10_x64_en-US-PA.iso,id=iso_install,if=none,format=raw -device scsi-cd,drive=iso_install \
-drive file=./win02.qcow,id=disk,format=qcow2,if=none,discard=on -device scsi-hd,drive=disk \
-cdrom ./virtio-win-0.1.126.iso \
-usb -usbdevice host:045e:0745 \
-soundhw hda \
-vga none \
-boot d

exit 0
