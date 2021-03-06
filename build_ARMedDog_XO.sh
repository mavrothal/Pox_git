#!/bin/bash
#a universal script to make an XO-1 and XO-1.5 compatible Puppy 
#from any woof (almost any) based Puppy Iso
#Please expand this outside of a pupsave if using Puppy.
#gpl3 (see /usr/share/doc) (c) mavrothal, 01micko
#NO WARRANTY

# bit of fun!
clear
echo "Welcome to Create ARMedXO Puppy"
xoolpcfunc()
{
echo ""
echo -en "\033[1;33m""\t1""\033[0m" "|" "\033[1;32m" "L""\033[0m" \
"|""\033[1;36m"" ->""\033[0m" "|""\033[1;35m" "X"; echo -e "\033[0m"
echo ""
}
export -f xoolpcfunc
xoolpcfunc

# version
VER=0.2

# workdir
PWD="`pwd`"
CWD="$PWD"

INSIDE=`echo $PWD | grep Pox_git`
if [ "$INSIDE" != "" ] ; then
	echo -e "\\0033[1;31m"
	echo "Running this script from within the Pox_git folder will fail"
	echo "Run it from the XO_build directory that make_build generates"
	echo -en "\\0033[0;39m"
	sleep 5
	exit 0
fi

# read config
. $CWD/pkgs_remrc

#ok, we exit on most errors, error function
statusfunc()
{
	if [ "$1" = "0" ];then echo -en "\033[0;32m" OK; echo -e "\033[0m" #green
		else echo -en "\033[0;31m" FAIL; echo -e "\033[0m" && exit #red
	fi	
}
export -f statusfunc

# clear old build
if [ -d build ];then
	echo -e "\\0033[1;31m"
	echo "A previuos build has been detected" 
	echo "You can quit the $0 prog now and save it or delete it"
	echo "and continue."
	echo "Hit \"d\" > \"enter\" to delete and continue or"
	echo "\"enter\" only to quit"
	echo -en "\\0033[0;39m"
	read DELETE
	if [ "$DELETE" = "d" ];then rm -rf build
		echo "Deleted previous build... continuing"
		else 
		echo "Exiting $0 so you can save your previous build"
		xoolpcfunc
		exit 0
	fi
fi

# usage
usagefunc()
{
	cat <<_USAGE
	Usage:
		This program modifies a standard Puppy iso or main sfs/initrd
		to be bootable on the XO olpc hardware, versions XO-1 and XO-1.5
	
		-h|--help	display this usage
		-v|--version	display script version
		-i|--img [path/to/dd_image]	the full pathname of the ARMed Puppy image
	
		(c) Created by mavrothal
		@murga-linux puppy forum
		GPLv3. See /usr/share/doc/legal/
		NO WARRANTY
		While all care is taken NO responsibility is accepted
_USAGE
	
	xoolpcfunc
	exit 0
}
export -f usagefunc

# set vars
XODIR="$CWD"
[ ! -d $XODIR/squashdir/squashfs-root ] && mkdir -p $XODIR/squashdir/squashfs-root
SQDIR="$XODIR/squashdir"
SFSROOT="$SQDIR/squashfs-root"
INITDIR="$XODIR"
XOSFS="$XODIR/XO_sfs"
extra_packs="$XODIR/extra_packs"
MNTDIR=""

# Make Build directory
rm -rf $CWD/build
mkdir -p $CWD/build/boot

Get_files_from_img ()
{
	if [ "$IMGPATH" != "" ];then 
	[ ! -d  $CWD/mntiso ] && mkdir $CWD/mntiso
	MNTDIR="$CWD/mntiso"
	echo "mounting $ISO"
	mount $IMGPATH $MNTDIR -o loop,offset=1048576,ro
	statusfunc $?
	#exit #testing
	cd $MNTDIR
	echo "looking for sfs files in iso"
	ls|grep "sfs$" >/dev/null 2>&1
	statusfunc $?
	
	SFSTHERE=`ls|grep "sfs$"`
	MAINSFS="`ls $SFSTHERE|grep "sfs$" | grep -v "^zdrv"|grep -v "^adrv"`"
	ZSFS=`echo $SFSTHERE|grep "zdrv"`
	if [ "$ZSFS" != "" ];then
		echo -e "\\0033[1;34m"
		echo  "A zdrv is present. You can manually search it for stuff needed "
		echo  "but is STRONGLY suggested to delete it. Hit \"d\" and enter to delete"
		echo  "or just \"enter\" to continue and merge it into the main SFS"
		echo -en "\\0033[0;39m"
		read ZDEL
		[ "$ZDEL" != "d" ] && cp zdrv*.sfs $SQDIR #why do we keep it?
	fi
	ASFS=`echo $SFSTHERE|grep "adrv"`
	if [ "$ASFS" != "" ];then
		echo -e "\\0033[1;34m"
		echo  "An adrv is present, you can manually search it for stuff needed"
		echo  "or delete it. Hit \"d\" and enter to delete or just \"enter\" "
		echo  "to continue and merge it into the main SFS."
		echo
		echo  "If you delete it now you can still include it in the XO build at the"
		echo  "end, though it may over-write some of the changes in the main SFS."
		echo -en "\\0033[0;39m"
		read ADEL
		[ "$ADEL" != "d" ] && cp adrv*.sfs $SQDIR
	fi
	cp $MAINSFS $SQDIR
	cp uInitrd* $INITDIR
	cd ..
	sync
	umount $MNTDIR
	rm -rf $MNTDIR
	sync
fi
}
export -f Get_files_from_img 

extra_packages ()
{
	if [ "$(ls $extra_packs)" != "" ]; then
		. $SFSROOT/etc/DISTRO_SPECS
		echo "The following packages were included in the build" >> $CWD/build.log
		cd $extra_packs
		for p in $(ls *.pet) 
		do 
			PNAME=`echo $p | sed 's/\.pet//'`
			tar xf $p 2>/dev/null
			cd $PNAME
			rm -f *.sh *.spec* 2>/dev/null
			cp -aR * $SFSROOT			
			if [ $? -ne 0 ]; then
				echo "Failed to add $p in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				echo "$p was added in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fi
			cd $extra_packs
			rm -rf $PNAME
			sync
		done
		case "$DISTRO_FILE_PREFIX" in 
		fd-arm)
			for p in $(ls *.tbz)
			do 
				( cd $SFSROOT 
				ROOT=$SFSROOT sbin/installpkg $extra_packs/$p 
				if [ $? -ne 0 ]; then
					echo "Failed to add $p in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				else
					echo "$p was added in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				fi
				sync
				cd $CWD )
			done
		;;
		esac		
	fi		
}
export -f extra_packages

delete_packages ()
{
	. $SFSROOT/etc/DISTRO_SPECS
	case "$DISTRO_FILE_PREFIX" in 
	fd-arm)
		echo "The following packages were removed from the fd-arm.sfs" >> $CWD/build.log
		for a in $FDARM
		do 
			( cd $SFSROOT 
			ROOT=$SFSROOT sbin/removepkg $a 
			if [ $? -ne 0 ]; then
				echo "Failed to remove $a from the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				echo "$a was removed from the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fi
			sync
			cd $CWD )
		done
	;;
	esac		
}
export -f delete_packages

mod_fd-arm ()
{
	delete_packages

	extra_packages

	# add /run and /run/udev directories for newer udev and didtros
	mkdir -p $SFSROOT/tmp/udev
	# Add support for the XO internal drives in fstab
	cat << EOF >> $SFSROOT/etc/fstab
/dev/mmcblk0p2		/.intSD	    ext4	defaults,noauto	  0 0
EOF
	# link gtkdialog to gtkdialog
	ln -sf /usr/bin/gtkdialog $SFSROOT/usr/bin/gtkdialog3
	# Fix clock
	cat << EOF > $SFSROOT/etc/hwclock.conf
HWCLOCKPARM='--utc -f /dev/rtc1'
EOF
	sed -i "s/HWCLOCKPARM}'/HWCLOCKPARM} -f \/dev\/rtc1'/" $SFSROOT/sbin/hwclockconf.sh
	sed -i 's/localtime/utc/' $SFSROOT/etc/rc.d/init.d/60-ntpd-client
	sed -i "s/ntpd -n/sleep 60; ntpd -n/" $SFSROOT/etc/rc.d/init.d/60-ntpd-client
	rm -f $SFSROOT/etc/rc.d/init.d/03-lasttime
	# Add 3-button emulation
	cat << EOF >> $SFSROOT/etc/X11/xorg.conf.d/20-olpc-mouse.conf
Section "InputClass"
        Identifier "evdev emulate 3 buttons"
        MatchIsPointer "on"
        MatchDevicePath "/dev/input/event*"
        Option "Emulate3Buttons" "true"
EndSection
EOF
	# adjust for the 200dpi XO screens
	cat << EOF >> $SFSROOT/root/.gtkrc.mine

# -- Adjust font size for XO screen
style "font"
{
font_name = "DejaVu Sans 12"
}
widget_class "*" style "font"
gtk-font-name = "DejaVu Sans 12" 

EOF
	sed -i 's/DejaVu Sans Bold 10/DejaVu Sans Bold 12/' \
		$SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/Options
	sed -i 's/DejaVu Sans 10/DejaVu Sans 12/' \
		$SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/Options
	sed -i 's/128/140/g' $SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/PuppyPin
	sed -i 's/214/258/g' $SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/PuppyPin
	sed -i 's/208/258/g' $SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/PuppyPin
	sed -i 's/46/48/g' $SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/PuppyPin
	sed -i 's/240/256/g' $SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/PuppyPin
	sed -i 's/298/370/g' $SFSROOT/etc/xdg/rox.sourceforge.net/ROX-Filer/PuppyPin
	sed -i 's/\<size\>10/\<size\>12/g' $SFSROOT/etc/xdg/openbox/rc.xml
	sed -i 's/\<size\>8/\<size\>11/g' $SFSROOT/etc/xdg/openbox/rc.xml
	sed -i 's/X\=64/X\=128/g' $SFSROOT/etc/eventmanager
	#Default to net-setup if present
	if [ "$(ls $extra_packs/net_setup*)" != "" ]; then
		cat << EOF > $SFSROOT/usr/local/bin/defaultconnect
#!/bin/sh
exec net-setup.sh
EOF
	    chmod 755 $SFSROOT/usr/local/bin/defaultconnect
	    #... and add a menu entry
	    cat << EOF > $SFSROOT/usr/share/applications/Network-Wizard.desktop
[Desktop Entry]
Name=Classic Network wizard
Exec=net-setup.sh
Icon=network24
X-FullPathIcon=/usr/share/pixmaps/midi-icons/network24.png
Type=Application
Categories=Network;
EOF
	fi
	# Fix sound
	rm -f $SFSROOT/etc/asound.conf
	#Rotate powerd.trace
	cat << EOF >> $SFSROOT/etc/rc.d/rc.local.shutdown
kill -9 $(pidof powerd)
rm -f /etc/adjtime
rm -f /var/log/powerd.trace.old
mv /var/log/powerd.trace /var/log/powerd.trace.old
EOF
	# Remove battery monitor from panel
	tac $SFSROOT//usr/share/lxpanel/profile/default/panels/panel |\
		sed '/type \= batt/{N;s/\n.*//;}' | tac |  sed '/type \= batt/,+12d' > /tmp/newpanel
	cp -a --remove-destination /tmp/newpanel $SFSROOT//usr/share/lxpanel/profile/default/panels/panel
	rm -f /tmp/newpanel
	# Start networks latter
	sed -i 's/\/etc\/rc\.d\/rc\.network start \&//' $SFSROOT/etc/rc.d/rc.sysinit
	sed -i 's/echo \$\! > \$RC_NETWORK_PID//' $SFSROOT/etc/rc.d/rc.sysinit
	# Rename mlan
	cat << EOF >>$SFSROOT/lib/udev/rules.d/70-olpc-net.rules
SUBSYSTEM!="net", GOTO="olpc_net_end"
ACTION!="add", GOTO="olpc_net_end"

# XO-4 hardware: fix to wlan0
DRIVERS=="mwifiex_sdio", KERNEL=="mlan*", NAME="wlan0", GOTO="olpc_net_end"

LABEL="olpc_net_end"
EOF
	cp -a $SFSROOT/lib/udev/rules.d/70-olpc-net.rules $SFSROOT/etc/udev/rules.d/70-olpc-net.rules
}
export -f mod_fd-arm
 
mod_XO_sfs ()
{
	rm -rf $XOSFS/.xo-nand
	rm -rf $XOSFS/etc/{modprobe.d,X11}
	rm -rf $XOSFS/usr/local
	rm -f $XOSFS/root/Startup/{0check_ker_ver,freeramdaemon.sh,powerapplet_xo,\
	powerapplet3_xo,fix_card_pin,pup_ver.sh,udev_check.sh}
	rm -f $XOSFS/root/{.freeramdaemon.rc,.guvcviewrc}
	#Start power managenet
	cat << EOF > $XOSFS/etc/rc.d/rc.local
#!/bin/ash
modprobe zforce
# Make sure that needed devices are added
udevadm trigger  --action=add --subsystem-match="input" --subsystem-match="sound" \\
--subsystem-match="usb" --subsystem-match="sdio" --subsystem-match="net" \\
--subsystem-match="mmc" --subsystem-match="rtc"
udevadm settle

# Start Networking
/etc/rc.d/rc.network start &
echo \$! > /tmp/rc.network.pid
[ ! -f /tmp/net-up ] && touch /tmp/net-up

# start kbdshim and powerd
/usr/sbin/olpc-kbdshim-udev -f -l \\
	-b /usr/bin/olpc-brightness \\
	-V /usr/bin/olpc-volume \\
	-r /usr/bin/olpc-rotate \\
	-R /var/run/olpc-kbdshim_command \\
	-A /var/run/powerevents &
/usr/sbin/olpc-switchd -f -l -p 10 -F /var/run/powerevents &
/usr/sbin/powerd &
EOF
	# Fix kbdshim
	cat << EOF > $XOSFS/root/Startup/kbdshimfix
#!/bin/sh
RUNNING=\$(ps aux | grep kbdshim | grep volume)
if [ "\$RUNNING" != "" ]; then
	echo F9 > /var/run/olpc-kbdshim_command
fi
EOF
	chmod 755 $XOSFS/root/Startup/kbdshimfix
	# Fix keyboard
	cat << EOF > $XOSFS/etc/udev/rules.d/96-olpckeymap.rules
# Use device tree to identify XO-1.75/4 and apply OLPC keymap
ACTION=="remove", GOTO="olpc_keyboard_end"
KERNEL!="event*", GOTO="olpc_keyboard_end"
ENV{ID_INPUT_KEY}=="", GOTO="olpc_keyboard_end"
SUBSYSTEMS=="bluetooth", GOTO="olpc_keyboard_end"
SUBSYSTEMS=="usb", GOTO="olpc_keyboard_end"
IMPORT{file}="/etc/X11/keyboard"
IMPORT{program}="device-tree-val DEVTREE_COMPAT compatible"
ENV{DEVTREE_COMPAT}=="olpc,xo-1*", RUN+="keymap \$name olpc-xo"
ENV{DEVTREE_COMPAT}=="olpc,xo-cl*", RUN+="keymap \$name olpc-xo"
LABEL="olpc_keyboard_end"
EOF
	cp -a $XOSFS/etc/udev/rules.d/96-olpckeymap.rules \
		$XOSFS/lib/udev/rules.d/96-olpckeymap.rules
	mkdir -p $XOSFS/etc/X11
	cat << EOF > $XOSFS/etc/X11/keyboard
XKBMODEL="olpcm"
XKBLAYOUT="us"
XKBVARIANT="olpc"
EOF
	# Move Startup to /etc/xdg/
	mkdir -p $XOSFS/etc/xdg
	mv $XOSFS/root/Startup $XOSFS/etc/xdg/
}
export -f mod_XO_sfs

mod_sfs ()
{
	mod_fd-arm
	mod_XO_sfs
	#log list of XO-specific files included
	echo "The following XO-specific files where included in the build" >> $CWD/build.log
	y=$(printf "%s\n" "$XOSFS" | sed 's/[/]/\\&/g') # specific case
	find $XOSFS | sed s/$y//g >> $CWD/build.log
	# Copy the XO_sfs specific files
	echo "copying in the XO files"
	cp -aRf $XOSFS/* $SFSROOT/
	cp -aRf $XOSFS/.[a-zA-Z0-9]* $SFSROOT/
	cp -a $CWD/build.log $SFSROOT/usr/share/doc/
	statusfunc $?
	mksquashfs $SFSROOT/ $CWD/build/$MAINSFS
	sync
	cd $CWD
	rm -rf $SQDIR
}
export -f mod_sfs

extract_main_sfs ()
{
	NUMBER="`ls $SQDIR/*.sfs|wc -l`"
	if [ "$NUMBER" -gt "3" ];then echo "Something is wrong! $NUMBER sfs files"
		echo "Should not be more than 3 ... aborting..." && statusfunc 1
	fi

	cd $SQDIR
	if [ "$NUMBER" = "1" ] ; then
		echo "unsquashing $MAINSFS"
		rm -rf squashfs-root
		unsquashfs $MAINSFS
		sync
		rm -f $MAINSFS
	else
		for SFS in *.sfs
		do echo "unsquashing $SFS"
			unsquashfs -d $SFS.root $SFS	
			statusfunc $?||break #should unpack everything to squashfs-root, exit on fail
			sync
			statusfunc 0 && echo "decompressed $SFS successful"
			rm -f $SFS
			sync
		done
		# Combine the SFSs in squashfs-root
		echo "Merging the SFSs. May take some time..."
		ls | grep ".sfs.root" | tac > /tmp/DIRS
		MERGE="`cat /tmp/DIRS`"
		for LINE in $MERGE 
		do 
			cp -aR --remove-destination $LINE/* $SFSROOT/
			sync
			echo "$LINE was merged"
			rm -rf $LINE
			sync
		done
		rm /tmp/DIRS
	fi
}
export -f extract_main_sfs

mod_initrd ()
{
	if [ ! -d $CWD/XO175kernel/ -a ! -d $CWD/XO4kernel/ ]; then
		echo -e "\\0033[1;34m"
		echo  "Please first build the ARM kernel(s) with \"XOpup_kernel_builder.sh\""
		echo  "and then run the script again. Aborting"
		echo -en "\\0033[0;39m"
		exit 1
	fi
	
	for XV in 175 4
	do
	cd $CWD/initrdfs
	unsquashfs -d kernel-modules kernel-modules.sfs
	if [ -d $CWD/XO"$XV"kernel/lib/modules/ ]; then
		rm -rf kernel-modules/lib/modules/*
		rm -rf lib/modules/*
		cp -aR $CWD/XO"$XV"kernel/lib/modules/* kernel-modules/lib/modules/
		echo "Added XO-"$XV" kernel modules in initrd" >> $CWD/build.log
		# Add aufs-utils for this kernel if present
		if [ -d $CWD/"$XV"aufs_utils ]; then
		    cp -a --remove-destination $CWD/"$XV"aufs_utils/* kernel-modules/
		    echo "Added XO-"$XV" aufs_utils in initrd" >> $CWD/build.log
		fi
		sync
		rm -f kernel-modules.sfs
		rm -f kernel-modules/usr/bin/a10disp
		rm -f usr/bin/a10disp
		rm -f bin/a10disp

		mksquashfs kernel-modules/ kernel-modules.sfs
		rm -rf kernel-modules
		sync
		# Add kernel headers for this kernel
		tar xf $CWD/XO"$XV"kernel/kernel-headers-*.pet 2>/dev/null
		cp -aR kernel-headers-*/usr/* usr/
		rm -rf kernel-headers-*
		echo "Added XO-"$XV" kernel headers in initrd" >> $CWD/build.log
		sync
		if [ "$XV" = "175" ]; then
			IV=2
		else
			IV=4
		fi
		find . -print| cpio -H newc -o | gzip -9 > $CWD/build/boot/initrd."$IV"
		echo "Modified the XO-"$XV" initrd" >> $CWD/build.log
	fi
	done
	cd $CWD 
	rm -rf initrdfs
	# Add olpc.fth to the build
	cp -a boot_ARM/olpc.fth build/boot 
}
export -f mod_initrd

extract_initrd ()
{
	cd $CWD
	rm -rf initrdfs
	dd if=uInitrd-a10 of=initrd.img bs=64 skip=1
	mkdir -p initrdfs
	cd initrdfs
	cat ../initrd.img | cpio -i
	cd $CWD
	rm -f uInitrd-a10 initrd.img
}
export -f

add_kernels ()
{
	if [ ! -d $CWD/boot40/ -a ! -d $CWD/boot175/ ]; then
		echo -e "\\0033[1;34m"
		echo  "Please first build the ARM kernel(s) with \"XOpup_kernel_builder.sh\""
		echo  "and then run the script again. Aborting"
		echo -en "\\0033[0;39m"
		exit 1
	fi
	if [ -d $CWD/boot175/ ]; then
		cp -aR $CWD/boot175/config-* $CWD/build/boot/
		cp -aR $CWD/boot175/vmlinuz $CWD/build/boot/vmlinuz.2
		echo "Added the XO-1.75 kernel" >> $CWD/build.log
	fi
	if [ -d $CWD/boot40/ ]; then
		cp -aR $CWD/boot40/config-* $CWD/build/boot/
		cp -aR $CWD/boot40/vmlinuz $CWD/build/boot/vmlinuz.4
		echo "Added the XO-4 kernel" >> $CWD/build.log
	fi
	sync
}
export -f add_kernels

copy_to_device ()
{
	echo -e "\\0033[1;34m"
	echo "Would you like to copy the build files to a USBstick/SDcard?"
	echo "If yes, please mount the USB stick or SDcard *NOW* "
	echo "...and then hit \"c\" > enter to continue" 
	echo "or just hit enter to finish and transfer the files manually"
	read COPY
	if [ "$COPY" = "c" ];then
		DEVICE=`df | awk 'END { print $6 }'`
		echo "The files will be transferred to $DEVICE."
		echo "if this is OK, hit \"t\" > enter to continue"
		echo "if not, hit enter to finish and transfer the files manually"
		read TRANSFER
			if [ "$TRANSFER" = "t" ];then
				echo "Transferring... Will take some time..."
				rm -rf $DEVICE/boot
				cp -aR --remove-destination build/* $DEVICE/
				sync; sync
				umount $DEVICE
			else
				echo "Copy all files in the ./build directory to USB media/SD card"
				echo " Done!"
				sync
			fi
	else 
		echo "Copy all files in the ./build directory to USB media/SD card"
		echo " Done!"
	fi
	echo -en "\\0033[0;39m"

	xoolpcfunc
	statusfunc 0 

	echo -e "\\0033[1;34m"
	echo " Done!"
	echo -en "\\0033[0;39m"
}
export -f copy_to_device

case "$#" in
	0) usagefunc ;;
	[3-9])echo "too many arguments"; usagefunc ;;
esac

case $1 in 
	-h|--help) usagefunc && exit 0 ;;
	-v|--version) echo "$VER" && exit 0 ;;
	-i|--img) [ ! $2 ] && usagefunc
		IMGPATH=$2 
		IMG="`basename $IMGPATH`" 
		Get_files_from_img
		extract_initrd && mod_initrd && add_kernels
		extract_main_sfs && mod_sfs && copy_to_device ;;
esac
