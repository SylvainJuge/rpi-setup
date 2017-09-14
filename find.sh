#!/bin/bash -x

set -e
set -u
set -o pipefail

if [[ "${EUID}" -ne '0' ]]; then
	echo "this script requires to run as root"
	exit 1
fi

subnet="$(ip -o -f inet addr show | awk '/scope global/ {print $4}')"
found_ip="$(nmap -sP "${subnet}" | awk '/^Nmap/{ip=$NF}/B8:27:EB/{print ip}' | sed 's/[()]//g')"

[[ '' == "${found_ip}" ]] && (echo 'not found'; exit 1)
