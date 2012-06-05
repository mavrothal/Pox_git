#!/bin/sh

# check puppy mode and add a sync of the pupysave before suspend
#. /etc/rc.d/PUPSTATE
#if [ $PUPMODE = "13" ] || [ $PUPMODE = "7" ] ; then
#        snapmergepuppy
#fi

# workaround for swap and kernel 3.x
if [ "`uname -r | cut -c 1`" = "3" ] ; then
	HASSWAP=`cat /proc/swaps | grep [0-9] | awk '{print $1}'`
	if [ "$HASSWAP" != "" ] ; then
		echo $HASSWAP > /tmp/oldswap
		swapoff -a
	fi
fi

touch /tmp/sleeping.now
sync
sleep 3
exit 0
