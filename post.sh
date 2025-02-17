#!/usr/bin/bash
set -eo pipefail

## TODO - get the right partition for this 
sudo mount XXXXXXXXXXXXXXXXX /mnt
echo "https://mirror.freedif.org/pub/OpenBSD/" |sudo tee  /mnt/etc/installurl > /dev/null
sudo sed -i s^10.0.2.2^10.139.1.1^ /etc/resolv.conf
umount /mnt
