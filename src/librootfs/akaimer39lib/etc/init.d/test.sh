#!/bin/sh
if [ ! "iwconfig wlan0 | grep Avtobus" ]; then
echo `dmesg | tail -n $((LINES-10))` > /mnt/`hostname`_dmesg
/sbin/reboot
fi

