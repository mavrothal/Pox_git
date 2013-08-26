#!/bin/bash
# 
# This script will download, modify if needed, compile
# and prepare for installation, by the associated 
# create_xo_puppy script, programs from the OLPC git repositories.
#
# GPL2 (see /usr/share/doc) (c) mavrothal, 01micko
# NO WARRANTY

#ver
VER=0.1 

BASEDIR=`pwd`
CWD="$BASEDIR" 

INSIDE=`echo $BASEDIR | grep Pox_git`
if [ "$INSIDE" != "" ] ; then
	echo -e "\\0033[1;31m"
	echo "Running this script from within the Pox_git folder will fail"
	echo "Run it from the XO_build directory that make_build generates"
	echo -en "\\0033[0;39m"
	sleep 5
	exit 0
fi

if [ ! -d $BASEDIR/XO_SFS_sources ] ; then 
	mkdir $BASEDIR/XO_SFS_sources
fi

XO_sources="$BASEDIR/XO_SFS_sources"
patches="$BASEDIR/XO_sfs_patches"
output="$BASEDIR/XO_sfs"

#bit of fun! (curtesy of 01micko)
clear
xoolpcfunc()
{
echo ""
echo -en "\033[1;33m""\t1""\033[0m" "|" "\033[1;32m" "L""\033[0m" \
"|""\033[1;36m"" ->""\033[0m" "|""\033[1;35m" "X"; echo -e "\033[0m"
echo ""
}
export -f xoolpcfunc
xoolpcfunc

#usage
usagefunc()
{
cat <<_USAGE
Usage:
	This program will download sources from OLPC gits, patch them 
	if needed and make Puppylinux-compatible versions for the 
	OLPC XO-1 and XO-1.5 laptops
	
	-h|--help	display this usage
	-v|--version	display script version
	-d|--download 	only download all the sources
	-g|--get	Get binaries from OLPC builds
	-b|--build 	download and build everything
	-k|--kbdshim 	download and build olpc-kbdshim
	-p|--powerd 	download and build olpc-powerd
	
	(c) Created by mavrothal and 01micko @murga-linux puppy forum	
	GPLv2. See /usr/share/doc/legal/
	NO WARRANTY of any kind is given or implied 
	While all care is taken NO responsibility is accepted
_USAGE
	
xoolpcfunc
exit 0
}
export -f usagefunc

case "$#" in
0) usagefunc ;;
[2-9])echo "too many arguments"; usagefunc ;;
esac

# Download/update olpc-kbdshim
dnld_kbd()
{
	cd $XO_sources
	if [ ! -d "olpc-kbdshim" ] ; then
		git clone git://dev.laptop.org/users/pgf/olpc-kbdshim 2>&1
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download olpc-kbdshim sources."
			echo "Check the connection and try again"
			echo -en "\\0033[0;39m"
			exit 1
		fi
		sync
	else 
		cd olpc-kbdshim
		git reset --hard HEAD@{1}
		git clean -fdx
		git fetch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to update olpc-kbdshim  sources."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "with the old sources or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "olpc-kbdshim git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi
		sync
	fi
}
export -f dnld_kbd

# Download/update olpc-powerd
dnld_powerd()
{
	cd $XO_sources
	if [ ! -d "powerd" ] ; then
		git clone git://dev.laptop.org/users/pgf/powerd 2>&1
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download olpc-powerd sources."
			echo "Check the connection and try again"
			echo -en "\\0033[0;39m"
			exit 1
		fi
		sync
	else 
		cd powerd
		git reset --hard HEAD@{1}
		git clean -fdx
		git fetch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to update olpc-powerd sources."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "with the old sources or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "powerd git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi
		sync
	fi	
}
export -f dnld_powerd

# Check if we have development tools installed
check_dev()
{
	if [ -f /etc/rc.d/BOOTCONFIG ] ; then
		. /etc/rc.d/BOOTCONFIG
		DEVX=`echo "$EXTRASFSLIST" | grep devx` 
		if [ "$DEVX" = "" ] ; then
		if [ "$(uname -m)" != "x86_64" -o "$(uname -m | grep -i armv7)" != "" ]; then
			echo -e "\\0033[1;31m"
			echo "You _must_ have devx loaded or run an x86_64 or ARMv7 distribution"
			echo "with devel files, for this script to run properly. Exiting"
			echo -en "\\0033[0;39m"
			xoolpcfunc
			exit 0
		fi
	fi
	else
		if [ "`which gcc | grep no\ `" != "" ] || [ `which gcc` = "" ] \
		|| [ "`which make | grep no\ `" != "" ] || [ `which make` = "" ] ; then
			echo -e "\\0033[1;31m"
			echo "You _must_ have development tools  installed for this script"
			echo " to run properly. Please install them and try again"
			echo -en "\\0033[0;39m"
			xoolpcfunc
			exit 0
		fi
	fi
	#Check if we have git
	if [ "`which git`" = "" ] ; then
		echo -e "\\0033[1;31m"
		echo "You _must_ have git  installed for this script"
		echo " to run properly. Please install git and try again"
		echo -en "\\0033[0;39m"
		xoolpcfunc
		exit 0
	fi
	# Check if we have rsync
	if [ "`which rsync`" = "" ] ; then
		echo -e "\\0033[1;31m"
		echo "You _must_ have rsync  installed for this script"
		echo " to run properly. Please install rsync and try again"
		echo -en "\\0033[0;39m"
		xoolpcfunc
		exit 0
	fi
	# Check if we cross-compile
	if [ "`uname -m | grep -i armv7`" = "" ] ; then
		# Check if we have the armv7 cross-compile gcc
		if [ ! -f /opt/crosstool/gcc-4.6.0/bin/armv7-unknown-linux-gnueabi-gcc-4.6.0 ] \
		&& [ ! -f /usr/bin/arm-linux-gnu-gcc ] ; then
			echo -e "\\0033[1;31m"
			echo " You need to have an ARM cross compiler installed to compile the XO-1.75 ARM kernel."
			echo -en "\\0033[0;39m"
			if [ -f /etc/fedora-release ] && [ "`cat /etc/issue | grep -i fedora`" != "" ] ; then
				echo -e "\\0033[1;34m"
				echo " Pleas yum install gcc-arm-linux-gnu and run the script again."
				echo -en "\\0033[0;39m"
				exit 1
			elif [ "`uname -m | grep x86_64`" != "" ] ; then
				echo -e "\\0033[1;34m"
				echo " Please download gcc-4.6.0-from-x86_64-to-armv7 from here"
				echo " http://dev.laptop.org/~cjb/gcc-4.6.0-from-x86_64-to-armv7.tar.bz2"
				echo " extract it in /opt/crosstool and run the script again"
				echo -en "\\0033[0;39m"
				exit 1
			else 
				echo -e "\\0033[1;31m"
				echo " You need to be running an x86_64 OS or a recent Fedora build"
				echo " for this script to work. Exiting..."
				echo -en "\\0033[0;39m"
				exit 1
			fi	
		fi			
	fi
}
export -f check_dev

# Build and copy olpc-kbdshim files
bld_kbd()
{
	mkdir -p $output/usr/bin
	mkdir -p $output/usr/sbin
	# Cross compile if needed
	if [ "`uname -m | grep -i armv7`" = "" ] ; then
		if [ ! -f /etc/fedora-release ] && [ "`cat /etc/issue | grep -i fedora`" = "" ] ; then
		 	export PATH=/opt/crosstool/gcc-4.6.0/bin:$PATH
			export ARCH=arm
			export CROSS_COMPILE=armv7-unknown-linux-gnueabi-
		else 
			export ARCH=arm
			export CROSS_COMPILE=arm-linux-gnu-
		fi
	fi
	
	cd $XO_sources/olpc-kbdshim
	git reset --hard HEAD@{1}
	git checkout origin/master
	# feeze to version 19 for now
	# git checkout cf77c1b19fa002b309cc9ccb8a3dc16ef35ef687
	make clean
	make olpc-kbdshim-udev
	if [ $? -ne 0 ]; then
		echo -e "\\0033[1;31m"
		echo "Error: failed compile olpc-kbdshim-udev."
		echo -en "\\0033[0;39m"
		echo "Error: failed compile olpc-kbdshim-udev. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	else
		echo "Compiled olpc-kbdshim-udev. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log			
	fi
	strip -s olpc-kbdshim-udev
	patch -p1 < $patches/olpc-rotate.patch
	if [ $? -ne 0 ]; then
		echo "Failed to patch olpc-rotate. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	else
		echo "Patch olpc-rotate. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	cp -a --remove-destination olpc-kbdshim-udev $output/usr/sbin
	cp -a --remove-destination olpc-rotate $output/usr/bin
	cp -a --remove-destination olpc-volume $output/usr/bin
	cp -a --remove-destination olpc-brightness $output/usr/bin
	sync
	make clean
}
export -f bld_kbd

# Build and copy powerd files
bld_powerd()
{
	mkdir -p $output/usr/bin
	mkdir -p $output/usr/sbin
	mkdir -p $output/etc/powerd/flags
	mkdir -p $output/etc/powerd/postresume.d/
	mkdir -p $output/etc/powerd/presuspend.d/
	
	cd $XO_sources/powerd
	git reset --hard HEAD@{1}
	git checkout origin/master
	cp $patches/powerd_master.patch $patches/powerd.patch

	# Cross compile if needed
	if [ "`uname -m | grep -i armv7`" = "" ] ; then
		if [ ! -f /etc/fedora-release ] && [ "`cat /etc/issue | grep -i fedora`" = "" ] ; then
		 	export PATH=/opt/crosstool/gcc-4.6.0/bin:$PATH
			export ARCH=arm
			export CROSS_COMPILE=armv7-unknown-linux-gnueabi-
		else 
			export ARCH=arm
			export CROSS_COMPILE=arm-linux-gnu-
		fi
	fi
	make clean
	make olpc-switchd
	if [ $? -ne 0 ]; then
		echo -e "\\0033[1;31m"
		echo "Error: failed compile olpc-switchd."
		echo -en "\\0033[0;39m"
		echo "Error: failed compile olpc-switchd. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	else
		echo "Compiled olpc-switchd. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log			
	fi
	strip -s olpc-switchd
	# Cross compile if needed
	if [ "`uname -m | grep -i armv7`" = "" ] ; then
		if [ ! -f /etc/fedora-release ] && [ "`cat /etc/issue | grep -i fedora`" = "" ] ; then
		 	export PATH=/opt/crosstool/gcc-4.6.0/bin:$PATH
			export ARCH=arm
			export CROSS_COMPILE=armv7-unknown-linux-gnueabi-
		else 
			export ARCH=arm
			export CROSS_COMPILE=arm-linux-gnu-
		fi
	fi
	make pnmto565fb
	if [ $? -ne 0 ]; then
		echo -e "\\0033[1;31m"
		echo "Error: failed compile pnmto565fb."
		echo -en "\\0033[0;39m"
		echo "Error: failed compile pnmto565fb. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	else
		echo "Compiled pnmto565fb. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log			
	fi
	strip -s pnmto565fb
	if [ -f usblist.c ] ; then
		make usblist
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed compile usblist."
			echo -en "\\0033[0;39m"
			echo "Error: failed compile usblist. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			strip -s usblist
			echo "Compiled usblist. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log			
		fi
	fi
	patch -p1 < $patches/powerd.patch 
	if [ $? -ne 0 ]; then
		echo "Failed to patch powerd. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	else
		echo "Patch powerd. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	patch -p1 < $patches/powerd_conf.patch
	if [ $? -ne 0 ]; then
		echo "Failed to patch powerd-conf. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	else
		echo "Patch powerd-conf. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	VERSION=`cat Makefile | grep ^VERSION= | cut -d "=" -f 2` 
	echo "powerd_version='version "$VERSION"'" > version
	cp -a --remove-destination powerd $output/usr/sbin
	cp -a --remove-destination olpc-switchd $output/usr/sbin
	cp -a --remove-destination pnmto565fb $output/usr/bin
	cp -a --remove-destination usblist $output/usr/bin
	cp -a --remove-destination powerd-config $output/usr/bin
	cp -a --remove-destination olpc-nosleep $output/usr/bin
	cp -a --remove-destination pleaseconfirm.* $output/etc/powerd
	cp -a --remove-destination version $output/etc/powerd
	cp -a --remove-destination shuttingdown.* $output/etc/powerd
	cp -a --remove-destination usb-inhibits $output/etc/powerd/flags
	cp -a --remove-destination powerd.conf.dist $output/etc/powerd/powerd.conf
	sync
	make clean	
}
export -f bld_powerd


# Get binary files from OLPC builds
get_binaries()
{	
	mkdir -p $output/lib/firmware/{libertas,mrvl}
	mkdir -p $output/usr/sbin
	echo "Getting the wireless firmware etc from OLPC"
	rsync --list-only rsync://updates.laptop.org/ > /tmp/avail_builds
	if [ "$(cat /tmp/avail_builds | grep 'xo1.75-13')" = "" -o "$(cat /tmp/avail_builds | grep 'xo4-13')" = "" ] ; then
		echo "The builds are not currently in the rsync server. "
		echo "Will take 5 to 10 minutes to be pulled in the server." 
		echo "Be patient..."
	fi
	# Get wireless firmware
	rsync -a rsync://updates.laptop.org/build-13.2.0_xo1.75-13/root/lib/firmware/libertas/sd8686_v9* \
		"$output"/lib/firmware/libertas
	if [ $? -ne 0 ]; then
		echo -e "\\0033[1;31m"
		echo "Error: failed to download the XO-1.75 firmware."
		echo -e "\\0033[1;34m"
		echo "Hit \"c\"  and then  \"enter\" to continue"
		echo "(the XO-1.75 will have no network)  or just \"enter\" to quit,"
		echo "check the connection and try latter."
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" = "c" ];then
			echo "sd8686_v9 download failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			exit 0
		fi
	else 
		echo "Downloaded sd8686_v9. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	rsync -a rsync://updates.laptop.org/build-13.2.0_xo4-13/root/lib/firmware/mrvl/sd8787_uapsta.bin \
		"$output"/lib/firmware/mrvl
	if [ $? -ne 0 ]; then
		echo -e "\\0033[1;31m"
		echo "Error: failed to download the XO-4 firmware."
		echo -e "\\0033[1;34m"
		echo "Hit \"c\"  and then  \"enter\" to continue"
		echo "(the XO-1.5 will have no network)  or just \"enter\" to quit,"
		echo "check the connection and try latter."
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" = "c" ];then
			echo "sd8787_uapsta* download failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			exit 0
		fi
	else 
		echo "Downloaded sd8787_uapsta. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi	
		
	# Get the full version of rtcwake
	rsync -a rsync://updates.laptop.org/build-13.2.0_xo4-13/root/usr/sbin/rtcwake \
		"$output"/usr/sbin/
	if [ $? -ne 0 ]; then
		echo -e "\\0033[1;31m"
		echo "Error: failed to download rtcwake."
		echo -e "\\0033[1;34m"
		echo "Hit \"c\"  and then  \"enter\" to continue"
		echo "(power management may not work)  or just \"enter\" to quit,"
		echo "check the connection and try latter."
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" = "c" ];then
			echo "rtcwake download failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			exit 0
		fi
	else
		echo "Downloaded rtcwake. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	sync; sync
}
export -f get_binaries

# Fix file mode, since all files in git are just wr
fix_mod()
{
	sync; sync
	sleep 5
	chown -R root:root $output/*
	chown -R root:root $BASEDIR/$DISTRO_FILE_PREFIX/*
	chmod 755 $output/sbin/*
	chmod 755 $output/usr/sbin/*
	chmod 755 $output/usr/bin/*
	chmod 755 $output/usr/local/bin/*
	chmod 755 $output/root/Startup/*
	chmod 755 $output/lib/udev/device-tree-val
	chmod 755 $output/etc/powerd/postresume.d/*
	chmod 755 $output/etc/powerd/presuspend.d/*
}
export -f fix_mod	

finished()
{
		echo -e "\\0033[1;34m"
		echo " Done! "
		echo "The files have been places in their respective directories," 
		echo "within the the $output folder."
		echo "They are ready to be copied to the sfs_root of you XO-specific puppy build."
		echo -en "\\0033[0;39m"
		xoolpcfunc
		echo "Finished making SFS files. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		cd $CWD
		exit 0

}
export -f finished



case $1 in 
-h|--help) usagefunc && exit 0 ;;
-v|--version) echo "$VER" && exit 0 ;;
-xh|--extended-help) echo "Coming soon..." 
					xoolpcfunc && exit 0 ;;	
-d|--download) check_dev && dnld_kbd	&& dnld_powerd && dnld_chrome ;;
-g|--get) check_dev && get_binaries && finished ;;
# -s|--pets) get_pets && finished ;;
-b|--build) check_dev && dnld_kbd && dnld_powerd && dnld_chrome
			 bld_kbd  && bld_powerd && get_binaries
			 fix_mod && finished ;; # && get_pets
-k|--kbdshim) check_dev && dnld_kbd && bld_kbd && fix_mod && finished ;;	
-p|--powerd) check_dev && dnld_powerd  && bld_powerd && fix_mod && finished ;;
esac

		
