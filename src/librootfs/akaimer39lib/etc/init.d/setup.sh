#!/bin/sh
echo heartbeat > /sys/class/leds/g_led/trigger
sed -i '/wlan0/d' /etc/mdev.conf
Server=$(cat /etc/param | grep Server= | cut -d "=" -f 2)
echo `cat /etc/param | grep HOST= | cut -d "=" -f 2` > /etc/sysconfig/HOSTNAME
hostname -F /etc/sysconfig/HOSTNAME
chmod 600 /etc/.rsync

# Dropbear
if [ -d /etc/dropbear ]; then rm -rf /etc/dropbear; fi
mkdir -p /etc/dropbear
chmod 700 /etc/dropbear
dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key

echo 1 > /sys/class/leds/r_led/brightness
while [ ! -d /sys/class/net/wlan0 ]
do
echo "Connect power adapter"
sleep 5
done
echo 0 > /sys/class/leds/r_led/brightness

# Wifi connect
if pgrep wpa_supplicant; then kill `pgrep wpa_supplicant`; fi
sleep 2
wpa_supplicant -B -iwlan0 -Dwext -c /etc/wpa_supplicant.conf
sleep 1
/etc/init.d/wifi.sh
sleep 1
echo "Updating time"
rdate -s $Server
hwclock --systohc
echo `date`
dropbear -R -B
if [ ! -f /etc/mtab ]; then ln -s /proc/mounts /etc/mtab; fi
umount -l /mnt
yes | /usr/bin/mke2fs -t ext3 $(ls /dev/mmcblk0p*)
mount $(ls /dev/mmcblk0p*) /mnt
rm -rf /mnt/*
echo '-wlan0 root:root 0660 $/etc/init.d/off.sh' >> /etc/mdev.conf
echo 'wlan0 root:root 0660 @/etc/init.d/on.sh' >> /etc/mdev.conf
echo "Setup finished" >> /etc/`hostname`_setup
rsync -avm --no-o --no-g --password-file=/etc/.rsync /etc/`hostname`_setup root@$Server::video/ya.disk/Avtobus/`date +%Y%m%d`/
rm -f /etc/`hostname`_setup
reboot
