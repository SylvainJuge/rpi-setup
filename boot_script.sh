#!/bin/bash

set -e
set -u
set -o pipefail

boot_script=rpi-setup-boot.sh
boot_script_url=https://gist.githubusercontent.com/SylvainJuge/2f7c5e474dd2293522ac37e405dec691/raw/69a62ff821e597748d46b46e4328e61b928b7707/${boot_script}
boot_local_script=/tmp/${boot_script}

curl -s ${boot_script_url} \
    -o ${boot_local_script} \
    && chmod u+x ${boot_local_script} \
    && ${boot_local_script}

# disable execute script in case of success
[[ $? == 0 ]] && chmod u-x ${0}
