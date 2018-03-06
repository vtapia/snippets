#!/bin/bash
set -ex
SIZE="1G"
RDPATH="/mnt/ramdisk"

echo "Create compressed ramdisk"
sudo mkdir -p $RDPATH
sudo modprobe zram num_devices=1
echo $SIZE | sudo tee /sys/block/zram0/disksize
sudo mke2fs -q -m 0 -b 4096 -O sparse_super -L zram /dev/zram0
sudo mount -o relatime,nosuid,discard /dev/zram0 $RDPATH

#Remove with:
#sudo umount $RDPATH
#sudo cat /sys/class/zram-control/hot_add (pick id)
#sudo echo $ID > /sys/class/zram-control/hot_remove
