#!/bin/sh

# workaround for swap and kernel 3.x
# check if we had swap and restart it
if [ -f /tmp/oldswap ] ; then
	OLDSWAP=`cat /tmp/oldswap`
	while [ "`ls $OLDSWAP`" != "$OLDSWAP" ]
	do
	sleep 2
	done 
	swapon -a "$OLDSWAP"
	rm -f /tmp/oldswap
fi

#remove the sleeping file generated by merge.sh
rm -f /tmp/sleeping.now
