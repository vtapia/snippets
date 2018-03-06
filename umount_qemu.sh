#!/bin/bash
sudo umount $1
sudo nbd-client -d /dev/nbd0
