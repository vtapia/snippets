#!/bin/bash
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 $1
sudo mount /dev/nbd0p1 $2
