#!/bin/sh
. /etc/DISTRO_SPECS
KERVER=`uname -r`
gtkdialog-splash -icon /usr/share/icons/xo.png -close box -bg lightblue -timeout 8 -text "$(gettext "You are running ${DISTRO_NAME} for the XO-1 and XO-1.5
Puppy build: ${DISTRO_FILE_PREFIX}-${DISTRO_VERSION} 
Kernel:$KERVER ")" 
	