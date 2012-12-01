#!/bin/sh
. gettext.sh
export TEXTDOMAIN=udev_check.sh
# Check if we have the full udev
if [ ! -f /lib/udev/collect ] ; then
	# ...and kill powerd so user can work for more than 3 minutes...
	killall powerd
	killall olpc-switchd
	killall olpc-kbdshim-udev
	Xdialog  --title "$(gettext 'UDEV Missing')" --ok-label "$(gettext 'Install')" --yesno "$(gettext 'Please add the full udev package (with extras), version 151+, \nfrom the binary compatible distro, so keyboard and \npower management will work properly. \n\nAlternativelly you can restore most of the functionaluty \ninstalling the included no-udev-powerd.pet. \nMake sure you install it AFTER you have created a savefile')"  0 0 
	Install=$?
	if [ $Install -eq 0 ]; then
		petget /usr/local/share/no-udev-powerd.pet
		if [ $? -ne 0 ]; then
			HERE=`pwd`
			tar xvzf /usr/local/share/no-udev-powerd.pet
			cp -aR  $HERE/no-udev-powerd/* /
			exec $HERE/no-udev-powerd/pinstall.sh &
			sleep 1s
			rm -rf $HERE/no-udev-powerd
			rm -f /pinstall.sh
			rm -f /puninstall.sh
			rm -f /pet.specs
		fi
	fi
fi

