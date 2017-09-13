#!/bin/bash

set -e
set -u
set -o pipefail

# arguments
# 1: raspbian image
# 2: target sd card

if [[ "${EUID}" -ne '0' ]]; then
	echo "this script requires to run as root"
	exit 1
fi

img="${1?image file required}"
dev="${2?target device required}"

usage(){
	echo "usage : "
	echo ""
	echo "  ${0} raspbian.img /dev/sdcard"
	echo ""
	echo "where 'raspbian.img' is image file, and '/dev/sdcard' is a block device"
}

if [[ ! -f "${img}" ]]; then
	usage
	exit 1
fi
if [[ ! -b "${dev}" ]]; then
	usage
	exit 1
fi

echo "unmounting block device..."
# re-enable errors because it may be already unmounted
set +e
umount -v ${dev}*
set -e

echo "computing hash..."
hash="sha256: $(sha256sum ${img})"

echo "will write [ ${hash} ] --(to)--> [ ${dev} ]"
echo ""
echo "type 'Y' key to continue, any other to abort"
read -s -n 1 confirm

if [[ 'Y' != "${confirm}" ]]; then
	echo "canceled by user"
	exit 2
fi

echo "writing to ${dev}..."
unzip -p "${img}" | sudo dd of="${dev}" bs=4M conv=fsync
sync

echo "enable ssh by default"

# enable ssh by adding 'ssh' file in boot partition
rootPartition=$(blkid -t LABEL="boot" ${dev}* | sed 's/:.*//g')
tempMount=$(mktemp -d)
mount ${rootPartition} ${tempMount}
touch ${tempMount}/ssh
umount ${tempMount}
rm -rf ${tempMount}

echo "you can eject SD card and plug into Pi"
