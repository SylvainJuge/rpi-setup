Almost automated raspberry setup procedure from Debian/Ubuntu

# Steps

1. download image
2. write image to sd card

    sudo ./write.sh -i raspbian.zip -c /dev/sdc
    # where raspbian.zip is a downloaded archive of raspbian
    # and sdcard the root block device of your sdcard.

3. Boot Raspbery plugged on local LAN

- DHCP should assign an IP to your Raspberry
- use `sudo ./find.sh` to crawl local network for raspberries
- connect to it with SSH

4. install packages remotely using ansible

    # install roles dependencies
    ansible-galaxy install -r ./requirements.yml

# download latest image using bittorrent

    # install transmission-cli
    sudo apt install transmission-cli

    # regular raspbian image
    transmission-cli https://downloads.raspberrypi.org/raspbian_latest.torrent

    # lite raspbian image
    transmission-cli https://downloads.raspberrypi.org/raspbian_lite_latest.torrent


# requirements

    # ansible 2.x
    sudo apt install ansible

# dht22 wiring

https://learn.adafruit.com/dht-humidity-sensing-on-raspberry-pi-with-gdocs-logging/wiring

# TODO

- add systemd service to send dht22 metrics to thingsboard
- configure wifi with secured password storage (not plaintext)
- configure auto-update with schedule every day

- use nmcli to manage networks ?

- configure thingsboard server+client roles
