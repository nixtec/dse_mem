#!/bin/sh

exec > /var/dse/log/slscript.log 2>&1

modprobe slusb
for dev in $@ ; do
  devname="/dev/slusb$dev"
  [ ! -e "$devname" ] && mknod $devname c 243 $dev
  slmodemd /dev/slusb$dev&
done

while true; do
  sleep 1
  /sbin/mgetty -D ttySL0
done
