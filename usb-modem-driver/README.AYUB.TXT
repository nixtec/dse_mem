MODULE_LICENSE("GPL");

If it says non-GPL module, can't be loaded, use the above statement in
drivers/st7554.c

For USB devices, it uses '243' as major number. Minors will start from 0
For SERIAL devices, it uses '242' as major number. Minors will start from 0

These nodes are not created automatically. So create them if needed.

================/etc/rc.local=================
modprobe slusb
mknod /dev/slusb0 c 243 0
mknod /dev/slusb1 c 243 1
mknod /dev/slusb2 c 243 2
mknod /dev/slusb3 c 243 3
==============================================

2. Run soft modem application.

       # /usr/sbin/slmodemd [options] <device_name>

   Where device name is appropriate device node for your modem
   (look at output of 'dmesg' command).
   Run '/usr/sbin/slmodemd --help' for details.

   Examples:

       # /usr/sbin/slmodemd --country=USA /dev/slamr0

   , or for SmartUSB56 Modems:

       # /usr/sbin/slmodemd --country=ITALY /dev/slusb0


