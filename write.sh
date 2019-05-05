#!/bin/bash

set -e
set -u
set -o pipefail


# TODO
# - provide visual feedback while doing initial start (or executing updates)
# https://www.reddit.com/r/raspberry_pi/comments/86noni/controlling_onboard_leds_act_pwr_on_raspberry_pi/


# TODO : find a way to expand root fs on first start
# raspi-config --expand-rootfs
# >> seems not required for recent images
# it seems that raspi-config is being run on 1st boot from /etc/inittab with a root login
# >> we need to check that because it may not be the case anymore
# https://elinux.org/RPi_raspi-config#First-boot_activity
# it seem the raspi-config initial execution in /etc/profile.d
#
# TODO : find a way to disable piwiz execution at first login
# > finding the file where this is started
#
# TODO : find a way to set current timezone
# TODO : find a way to set current locale (and keyboard layout)
#
# TODO : change default ssh password for user 'pi'
#
# TODO : find a way to execute a command on boot
# should connect to a known URL and execute init script which contains
# - change default password for 'pi' user
# - install python and ansible
# - install ansible pull mode in crontab
# - execute ansible pull mode once
# - remove this command at boot

usage(){
	echo "usage : "
	echo ""
	echo "  ${0} -i raspbian.zip -d /dev/sdcard"
	echo ""
	echo "where 'raspbian.zip' is image file, and '/dev/sdcard' is target block device (sdcard)"
	echo ""
	echo "  optional arguments"
	echo ""
	echo "  -s 0|1                  : remote ssh 1=enable 0=disable"
	echo "  -n [your wifi ssid]     : set default wifi ssid"
	echo "  -p [your wifi password] : set default wifi password"
	echo "  -c [boot command]       : add command to execute on boot"
	echo ""
	echo "  examples"
	echo ""
	echo "  # write image to sdcard located at /dev/sdc"
	echo "  ${0} -i raspbian.zip -d /dev/sdc"
	echo ""
	echo "  # write image to sdcard with ssh enabled"
	echo "  ${0} -i raspbian.zip -d /dev/sdc -s 1"
	echo ""
	echo "  # write image to sdcard with wifi connection"
	echo "  ${0} -i raspbian.zip -d /dev/sdc -n 'wifi_ssid' -p 'wifi_pwd' "
	echo ""
	echo "  # write image to sdcard custom boot command"
	echo "  # if this command returns error code != 0 it will be removed from next boot"
	echo "  ${0} -i raspbian.zip -d /dev/sdc -c 'echo hello'"
	echo ""
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

if [[ "${EUID}" -ne '0' ]]; then
	echo "this script requires to run as root"
	exit 1
fi

img=""
dev=""

enable_ssh=0
wifi_ssid=""
wifi_pwd=""

while getopts ":i:d:s:n:p:y:" o; do
    case "${o}" in 
        i)
        img="${OPTARG}"
        ;;
        d)
        dev="${OPTARG}"
        ;;
        s)
        enable_ssh="${OPTARG}"
        ;;
        n)
        wifi_ssid="${OPTARG}"
        ;;
        p)
        wifi_pwd="${OPTARG}"
        ;;
        *)
        echo "unknown option ${o}"
        usage
        ;; 
    esac
done
shift $((OPTIND-1))

if [[ ! -f "${img}" ]]; then
    echo "${img} does not exists"
	usage
	exit 1
fi
if [[ ! -b "${dev}" ]]; then
    echo "'${img}' block device does not exists"
	usage
	exit 1
fi

echo "-----"
echo "enable remote ssh = $enable_ssh"
echo "wifi ssid = $wifi_ssid"
echo "wifi password = $wifi_pwd"
echo "source image = $img"
echo "target device = $dev"
echo "-----"

echo "unmounting block device..."
# re-enable errors because it may be already unmounted
set +e
umount -v ${dev}*
set -e

echo "computing hash, please wait (takes a while)..."
hash="sha256: $(sha256sum ${img})"
echo "you should check this value against hash available on raspbian webpage"

echo "will write [ ${hash} ] --(to)--> [ ${dev} ]"
echo ""
echo "type 'Y' key to continue, any other to abort"
read -s -n 1 confirm

if [[ 'Y' != "${confirm}" ]]; then
	echo "canceled by user"
	exit 2
fi

echo "writing to ${dev}, please wait... (takes a while)"

unzip -p "${img}" | sudo dd of="${dev}" bs=4M conv=fsync
sync


bootPartition=$(blkid -t LABEL="boot" ${dev}* | sed 's/:.*//g')
rootPartition=$(blkid -t LABEL="rootfs" ${dev}* | sed 's/:.*//g')

tempMount=$(mktemp -d)

# modify boot partition
if [[ '1' == "${enable_ssh}" ]]; then
    echo "> enable ssh by default"
    # enable ssh by adding 'ssh' file in boot partition
    touch ${tempMount}/ssh
fi
umount ${tempMount}

# modify root partition
mount ${rootPartition} ${tempMount}
if [[ '' != "${wifi_ssid}" ]]; then
    # configure wifi credentials
    echo "> set credentials for ${wifi_ssid} network"
    cat >> ${tempMount}/etc/wpa_supplicant/wpa_supplicant.conf <<EOF

# set country
country=$(curl https://ipinfo.io/ -s | grep country | sed 's/.*"\(..\)".*/\1/g')

# configure access to ${wifi_ssid}
$(wpa_passphrase "${wifi_ssid}" "${wifi_pwd}" | sed '/#psk/d' )
EOF

fi
umount ${tempMount}

rm -rf ${tempMount}

echo "you can eject SD card and plug into Pi"
