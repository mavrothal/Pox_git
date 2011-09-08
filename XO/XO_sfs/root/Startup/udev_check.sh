#!/bin/sh
if [ ! -d /lib/udev/devices ] ; then
gtkdialog-splash -fontsize large -bg hotpink -icon gtk-dialog-error -close box -timeout 15 -text "Please add the full udev package, version 151+, from the binary compatible distro so keyboard and power management will work properly" &
fi