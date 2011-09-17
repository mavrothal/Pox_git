#!/bin/sh
# Check if we have the full udev
if [ ! -f /lib/udev/collect ] ; then
	gtkdialog-splash -fontsize large -bg hotpink -icon gtk-dialog-error -close box -timeout 15 -text "Please add the full udev package, version 151+, from the binary compatible distro so keyboard and power management will work properly" &
	# ...and kill powerd so user can work for more than 3 minutes...
	killall powerd
fi
