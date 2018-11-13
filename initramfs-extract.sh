#!/bin/bash -e

INITRD=$1

function list_blocks() {
	while cpio -t ; do :; done < $1 2>&1| grep "[0-9] blocks"
}


function start_data_block() {
	SKIP=0
	for i in $(list_blocks $1); do SKIP=$((SKIP + i)); done
	echo $SKIP
}


function extract_efi_cpio() {
	SKIP=0
	COUNT=0
	IDX=1
	while cpio -t ; do :; done < initrd 2>&1| grep "[0-9] blocks" | while read COUNT blocks; do
		echo "dd if=$1 of=initrd_${IDX}.img bs=512 count=${COUNT} skip=${SKIP}"
		dd if=$1 of=initrd_efi${IDX}.img bs=512 count=${COUNT} skip=${SKIP}
		SKIP=$(($SKIP + $COUNT))
		((IDX++))
	done
}


function extract_data_cpio() {
	echo "dd if=$1 of=initrd_fs.img bs=512 skip=$2"
	dd if=$1 of=initrd_data.img bs=512 skip=$2
}


function extract_data() {
	TYPE=$(file initrd_data.img | awk '{print $2}')
	mkdir data
	echo $TYPE

	if [ $TYPE == "gzip" ]; then
	       mv initrd_data.img initrd_data.img.gz
	       cd data; zcat ../initrd_data.img.gz | cpio -idmv
	elif [ $TYPE == "LZMA" ]; then
	       mv initrd_data.img initrd_data.img.lzma
	       lzma -d initrd_data.img.lzma
	       cd data; cat ../initrd_data.img | cpio -idmv
	fi
}






SKIP=$(start_data_block $INITRD)
# Keep EFI together for an easy recombination
dd if=$INITRD of=initrd_efi_combined.img bs=512 count=$SKIP
extract_data_cpio $INITRD $SKIP
extract_data
