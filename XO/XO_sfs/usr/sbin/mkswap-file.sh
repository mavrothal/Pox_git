#!/bin/sh
# A script to generate a swap file in your XOpup boot partition
# mavrothal GPL 2011
# No warranties

. /etc/rc.d/PUPSTATE

BOOTPRT=`df | grep $PDEV1 | cut -d '%' -f 2 | tr -d '\ '`
FREEPART=`df -B M | grep $PDEV1 | cut -d 'M' -f 3 | tr -d '\ '`

SWP=`cat /proc/swaps | grep [0-9]`
if [ "$SWP" != "" ] ; then
	echo " Ooops! Swap is already available." 
	echo " Nothing to do here."
	echo " You may have too many apps open. Close some!"
	sleep 5
	exit 0
else
	if [ "$FREEPART" -lt "512" ] ; then
		echo " There is not enough free space in your boot device!"
		echo " Try deleting some files you may not need" 
		echo " You should have at least 512MB available to make swap"
		sleep 5
		exit 0
	else
		rm -rf $BOOTPRT/pupswap.swp 2> /dev/null
		sync
		sleep 1
		echo " Creating 256 MB swap file. Will take some time (1-2 minutes)..."
		dd if=/dev/zero of=$BOOTPRT/pupswap.swp bs=1M count=256
		sleep 3
		chmod 600 $BOOTPRT/pupswap.swp
		mkswap $BOOTPRT/pupswap.swp
		swapon -a $BOOTPRT/pupswap.swp
		echo " "
		echo " Done"
		echo " Swap is now available!"
		sleep 3
		exit 0
	fi
fi


