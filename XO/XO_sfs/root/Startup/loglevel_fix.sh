#!/bin/sh
. /etc/rc.d/PUPSTATE
if [ "$PUPMODE" != "5" ] ; then
 sed -i 's/ loglevel=7\" expand\$ to boot-file/\" expand\$ to boot-file/' /mnt/home/boot/olpc.fth 2> /dev/null
 rm -f /root/Startup/loglevel_fix.sh
fi