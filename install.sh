#!/usr/bin/bash
set -eo pipefail

#### Get the source
cd
mkdir -p /home/user/build/qubeized_images/OpenBSD/
cp -rv ~/QubesIncoming/qubes-builder/appmenus  /home/user/build
cd build

wget https://mirror.freedif.org/pub/OpenBSD/7.6/amd64/SHA256
wget https://mirror.freedif.org/pub/OpenBSD/7.6/amd64/SHA256.sig
wget https://mirror.freedif.org/pub/OpenBSD/7.6/amd64/install76.iso

mkdir firmware
cd firmware
wget --continue --accept "*.tgz" --no-directories --no-parent --recursive http://firmware.openbsd.org/firmware/$(uname -r)/

cd ..
tar zcf site76.tgz firmware

sudo mount install76.iso /mnt
mkdir pkgs
cp /mnt/7.6/amd64/*.tgz /mnt/7.6/amd64/bsd*  pkgs
sudo umount /mnt

### tftp server

mkdir /home/user/tftp
cp pkgs/bsd.rd /home/user/tftp/bsd.rd
cp ~/QubesIncoming/qubes-builder/pxeboot /home/user/tftp/auto_install

sudo nft add rule qubes custom-input udp dport 69 accept
sudo nft add rule qubes custom-input udp dport 67 accept

mkdir /home/user/tftp/etc/

cat <<EOF > /home/user/tftp/etc/boot.conf
boot tftp:/bsd.rd
EOF

# Generate random seed
dd if=/dev/random of=/home/user/tftp/etc/random.seed bs=512 count=1
chmod 644 /home/user/tftp/etc/random.seed

sudo systemctl start tftp

### http server
sudo mkdir -p /var/www/html/pub/OpenBSD/7.6/amd64
sudo cp pkgs/*  /var/www/html/pub/OpenBSD/7.6/amd64
sudo cp site76.tgz /var/www/html/pub/OpenBSD/7.6/amd64
sudo cp SHA256*  /var/www/html/pub/OpenBSD/7.6/amd64
ls -ln /var/www/html/pub/OpenBSD/7.6/amd64 |sudo tee /var/www/html/pub/OpenBSD/7.6/amd64/index.txt > /dev/null
sudo cp ~/QubesIncoming/qubes-builder/install.conf /var/www/html/
sudo cp ~/QubesIncoming/qubes-builder/disklabel /var/www/html/
sudo cp ~/QubesIncoming/qubes-builder/lighttpd.conf /etc/lighttpd/lighttpd.conf

sudo chown -R lighttpd:lighttpd /var/www/html/

sudo systemctl start lighttpd


### Create root.img and install
qemu-img create -f raw /home/user/build/qubeized_images/OpenBSD/root.img 20G

cd /home/user

echo "Kill the qemu-system call with Ctrl+C when install is complete if the VM does not shut down"

qemu-system-x86_64  -smp "cpus=2" -m 2G -drive "file=/home/user/build/qubeized_images/OpenBSD/root.img,media=disk,format=raw,if=virtio" -device e1000,netdev=net0 -netdev "user,id=net0,net=192.168.0.0/24,hostname=OpenBSD,tftp=tftp,bootfile=auto_install,hostfwd=tcp::2222-:22"

## 
#cd ~/QubesIncoming/qubes-builder/
#cp template.spec ..
#cp template.conf /home/user/build
#export TIMESTAMP=$(date +%Y%m%d%H%M)
#./build-template-rpm /home/user/build OpenBSD 0.2 $TIMESTAMP



## 
