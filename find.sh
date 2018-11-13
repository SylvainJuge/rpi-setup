#!/bin/bash

set -e
set -u
set -o pipefail

if [[ "${EUID}" -ne '0' ]]; then
	echo "this script requires to run as root"
	exit 1
fi

set +e
which nmap
if [[ $? != 0 ]]; then
    echo "this script requires nmap"
    exit 1
fi
set -e

subnets="$(ip -o -f inet addr show | awk '/scope global/ {print $4}')"
for subnet in ${subnets}; do
    echo "scanning subnet : ${subnet}"
    found_ip="$(sudo nmap -sP "${subnet}" | awk '/^Nmap/{ip=$NF}/B8:27:EB/{print ip}' | sed 's/[()]//g')"
    if [[ "" != "${found_ip}" ]]; then
        echo "found: ${found_ip}"
        exit 0
    fi
done

echo 'not found'
exit 1
