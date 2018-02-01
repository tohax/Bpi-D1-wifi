#!/bin/sh
echo 0 > /sys/class/leds/r_led/brightness
echo 0 > /sys/class/leds/g_led/brightness
2>/dev/null killall on.sh rsync wpa_supplicant
echo -e  "\n PowerOFF `date +"%x"" ""%X"`\n" >> /etc/`hostname`.txt
if [ ! `pidof record_video` ]; then
 /etc/init.d/camera.sh &
fi
