#!/bin/bash
set -x

ACTION=$1
DOM=$2
FILE=$3

verify_add() {
virsh dominfo $DOM >/dev/null 2>&1
if [[ $? != 0 ]]
then
	echo "Domain $DOM does not exist"
	exit 1
fi

if [ ! -s $FILE ]
then
	echo "Path $FILE does not exist"
	exit 1
fi
}

verify_del() {
virsh dominfo $DOM >/dev/null 2>&1
if [[ $? != 0 ]]
then
	echo "Domain $DOM does not exist"
	exit 1
fi
}

add() {
sudo virsh qemu-monitor-command --hmp $DOM "drive_add 0 if=none,format=raw,id=usbdisk1,file=$USB"
sudo virsh qemu-monitor-command --hmp $DOM "device_add usb-storage,id=usbdisk1,drive=usbdisk1"
}

create_disk() {
	USB="/tmp/usbdisk.img"
	MNT_DIR=$(mktemp -d)

	echo "Generating new floppy image: $USB"
	qemu-img create -f raw -o size=2G $USB

	mkfs.ntfs -F $USB
	sudo mount -o loop -t ntfs -o rw,uid=$UID $USB $MNT_DIR
	cp -r $FILE $MNT_DIR
	tree $MNT_DIR
	TOTAL_SIZE=`du -sh $MNT_DIR`
	echo "Total size: $TOTAL_SIZE"
	sync
	sudo umount $MNT_DIR
	sudo rmdir $MNT_DIR
	chmod 777 $USB

	echo "USB disk created."
}

delete_disk() {
	rm /tmp/usbdisk.img
}

del() {
virsh qemu-monitor-command --hmp $DOM "device_del usbdisk1"
}

case $ACTION in
	add )
		if [[ $# -ne 3 ]]; then
			echo "Wrong number of parameters"
			echo "Usage: $0 add <virsh domain> <file/dir to copy>"
			exit 1
		fi
		verify_add
		create_disk
		add
		;;
	del )
		if [[ $# -ne 2 ]]; then
			echo "Wrong number of parameters"
			echo "Usage: $0 del <virsh domain>"
			exit 1
		fi
		del
		delete_disk
		;;
	* )
		echo "$ACTION is not add/del"
		exit 1
		;;
esac

