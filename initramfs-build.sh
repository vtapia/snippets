#!/bin/bash -ex

## Create:
## find kernel/ | cpio -o -H newc > new_initrd.img
## cd base; find . | cpio -o -H newc | lzma -9 >> new_initrd.img

cp initrd_efi_combined.img new_initrd
cd data
find . | cpio -o -H newc | lzma -9 >> ../new_initrd
