#!/bin/sh

NAME=`cat /sys/class/dmi/id/product_name`
VER=`cat /sys/class/dmi/id/product_version`
SWP=`cat /proc/swaps | grep [0-9]`

. $HOME/.freeramdaemon.rc

naggui(){
	Xdialog --timeout 3 -msgbox "freeramdaemon is running"  0 0 0
}
export -f naggui

# Check if it is an XO-1 running without swap. 
# The XO-1.5 has 1GB RAM and swap on a slow SDcard will slow it down.

if [ "$NAME-$VER" = "XO-1" ] && [ "$SWP" = "" ]; then
	if [[ "$CB0" = "true" ]];then 
		exit 0
	fi
	if [[ "$CB1" = "false" ]];then 
		naggui &
		exec /usr/local/bin/freeramdaemon "$@" &
	fi
fi

exit 0

