#!/bin/sh
Server=$(cat /etc/param | grep Server= | cut -d "=" -f 2)
if pidof camera.sh; then kill `pidof camera.sh`; fi
if pidof record_video; then kill -SIGINT `pidof record_video`; fi
if pgrep wpa_supplicant; then kill `pgrep wpa_supplicant`; fi
sleep 1
if [ ! -d /sys/class/net/wlan0 ]; then /etc/init.d/off.sh; exit; fi
wpa_supplicant -B -iwlan0 -Dwext -c /etc/wpa_supplicant.conf
sleep 1
/etc/init.d/wifi.sh
dropbear -R -B
sleep 1
rdate -s $Server
hwclock --systohc
echo heartbeat > /sys/class/leds/r_led/trigger
sleep 1
echo heartbeat > /sys/class/leds/g_led/trigger
time=`date +%Y%m%d`
echo `date` > /etc/_ON_`hostname`.txt
find /mnt/ -name "*index" -exec rm {} \;
rsync -avz --remove-source-files --password-file=/etc/.rsync /etc/_ON_`hostname`.txt root@$Server::video/ya.disk/Avtobus/$time/
rsync -avW --size-only --progress --remove-source-files --log-file=/etc/`hostname`.txt --password-file=/etc/.rsync /mnt/ root@$Server::video/oneday/
rsync -avz --remove-source-files --password-file=/etc/.rsync /etc/`hostname`.txt root@$Server::video/ya.disk/Avtobus/$time/
find /mnt/[1-9]* -type d -delete 2>/dev/null
echo none > /sys/class/leds/g_led/trigger
echo none > /sys/class/leds/r_led/trigger
echo 0 > /sys/class/leds/g_led/brightness
echo 1 > /sys/class/leds/r_led/brightness
