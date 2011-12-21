#!/bin/sh
# Check if we have the full udev
if [ ! -f /lib/udev/collect ] ; then
	# ...and kill powerd so user can work for more than 3 minutes...
	killall powerd
	killall olpc-switchd
	killall olpc-kbdshim-udev
	Xdialog  --title "UDEV Missing" --ok-label "Install" --yesno "Please add the full udev package (with extras), version 151+, \nfrom the binary compatible distro, so keyboard and \npower management will work properly. \n\nAlternativelly you can restore most of the functionaluty \ninstalling the included no-udev-powerd.pet"  0 0 
	Install=$?
	if [ $Install -eq 0 ]; then
		petget /usr/local/share/no-udev-powerd.pet
	fi
fi

