#!/bin/sh
AP=$(cat /etc/param | grep AP= | cut -d "=" -f 2)
if [ ! "iwconfig wlan0 | grep $AP" ]; then
echo `dmesg | tail -n $((LINES-10))` > /mnt/`hostname`_dmesg
/sbin/reboot
fi

