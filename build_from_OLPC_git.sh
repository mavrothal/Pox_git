#!/bin/bash
# 
# This script will download, modify if needed, compile
# and prepare for installation, by the associated 
# create_xo_puppy script, programs from the OLPC git repositories.
#
# GPL2 (see /usr/share/doc) (c) mavrothal, 01micko
# NO WARRANTY

#ver
VER=5 

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
	-c|--chrome	download and build xf86-video-chrome
	
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

# Download/update xf86-video-chrome
dnld_chrome()
{
	cd $XO_sources
	if [ ! -d "xf86-video-chrome" ] ; then
		git clone git://dev.laptop.org/users/jnettlet/xf86-video-chrome 2>&1
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download xf86-video-chrome sources."
			echo "Check the connection and try again"
			echo -en "\\0033[0;39m"
			exit 1
		fi
		sync
	else 
		cd xf86-video-chrome
		git reset --hard HEAD@{1}
		git clean -fdx
		git fetch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to update xf86-video-chrome sources."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "with the old sources or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "xf86-video-chrome git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi
		sync
	fi	
}
export -f dnld_chrome

# Check if we have development tools installed
check_dev()
{
	if [ -f /etc/rc.d/BOOTCONFIG ] ; then
		. /etc/rc.d/BOOTCONFIG
		DEVX=`echo "$EXTRASFSLIST" | grep devx` 
		if [ "$DEVX" = "" ] ; then
			echo -e "\\0033[1;31m"
			echo "You _must_ have devx loaded for this script to run properly"
			echo "Please load the devx SFS and try again"
			echo -en "\\0033[0;39m"
			xoolpcfunc
			exit 0
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
}
export -f check_dev

# Build and copy olpc-kbdshim files
bld_kbd()
{
	mkdir -p $output/usr/bin
	mkdir -p $output/usr/sbin
	
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
	# check what kernel are we using
	KERVER1=`ls $BASEDIR/boot10/ | grep config | cut -f 2 -d '-' | cut -f1 -d'.'`
	KERVER2=`ls $BASEDIR/boot15/ | grep config | cut -f 2 -d '-' | cut -f1 -d'.'`
	if [ "$KERVER1" = "2" ] || [ "$KERVER2" = "2" ] ; then
		git checkout f61b0feb40bff536fc86126468626b4585fe3c3d
		cp $patches/powerd_42.patch $patches/powerd.patch
	else
		cp $patches/powerd_master.patch $patches/powerd.patch
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

# Build puppy-specific chrome driver
bld_chrome()
{
	# TODO: needs a dependency check before compile.
	# It fails in lupu-528 for example, but OK in slacko
	
	. /etc/DISTRO_SPECS
	BLDCHROME=""
	cd $XO_sources/xf86-video-chrome
	git reset --hard HEAD@{1}
	chmod 755 autogen.sh
	[ "$BUILDNAME" = "" ] && BUILDNAME=`pwd`
	CORRECT=`echo $BUILDNAME | grep $DISTRO_FILE_PREFIX`
	if [ "$CORRECT" = "" ] ; then
		echo -e "\\0033[1;34m"
		echo "The chrome driver is NOT compatible with all puppies."
		echo "You MUST be running the puppy version you want to"
		echo "adapt for the OLPC XO-1.5, to make a functional driver"
		echo ""
		echo "Hit \"c\"  and then  \"enter\" to continue"
		echo "with compilation or just \"enter\" to skip chrome,"
		echo "load the appropriate puppy version and run the script again."
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" = "c" ];then 
			echo "Chrome driver may have not been compiled in a compatible distro. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			echo "User did not build the XO-1.5 chrome video driver. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fix_mod
			finished
		fi
	fi

	if [ "$DISTRO_FILE_PREFIX" != "" ] ; then 
		mkdir -p $BASEDIR/"$DISTRO_FILE_PREFIX"/xorg/modules/drivers
	else 
		mkdir -p $BASEDIR/CHROME_DRIVER/xorg/modules/drivers
	fi
	
	git reset --hard HEAD@{1}
	make clean
	chmod 755 autogen.sh
	./autogen.sh
	if [ $? -ne 0 ]; then
		echo "Chrome compilation failed. Looks like you miss some dependencies. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	make
	if [ $? -ne 0 ]; then
		# Latest chrome will not build on older xserver
		make clean distclean
		git reset --hard HEAD
		git clean -xdf
		patch -p1 < $patches/chrome-ARRAY_SIZE.patch
		chmod 755 autogen.sh
		./autogen.sh
		make
		if [ $? -ne 0 ]; then
			echo "Chrome compilation failed. Try co compile from within the " >> $CWD/build.log
			echo ".../XO_sfs_sources/xf86-video-chrome directory to check. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			echo "chrome_drv.so was compiled successfully. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	else
		echo "chrome_drv.so was compiled successfully. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	strip -s src/.libs/chrome_drv.so	
	sync
	cp -a src/.libs/chrome_drv.so $BASEDIR/$DISTRO_FILE_PREFIX/xorg/modules/drivers
	BLDCHROME="yes"
}
export -f  bld_chrome

# Get binary files from OLPC builds
get_binaries()
{	
	mkdir -p $output/lib/firmware
	mkdir -p $output/usr/sbin
	if [ "`ls $CWD/boot1* | grep '3\.3'`" != "" ] ; then
		mkdir $output/lib/firmware/libertas
	fi
	echo "Getting the wireless firmware etc from OLPC"
	rsync --list-only rsync://updates.laptop.org/ > /tmp/avail_builds
	if [ "`ls $CWD/boot1* | grep '2\.6'`" != "" ] ; then
	if [ "`cat /tmp/avail_builds | grep 'xo1-885'`" = "" ] || [ "`cat /tmp/avail_builds | grep 'xo1.5-885'`" = "" ] ; then
		echo "The builds are not currently in the rsync server. "
		echo "Will take 5 to 10 minutes to be pulled in the server." 
		echo "Be patient..."
	fi
	# Get wireless firmware
	rsync -a rsync://updates.laptop.org/build-official_xo1-885/root/lib/firmware/usb8388.bin \
		"$output"/lib/firmware/
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the XO-1 firmware."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "(the XO-1 will have no network)  or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "usb8388.bin download failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		else 
			echo "Downloaded usb8388.bin. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	rsync -a rsync://updates.laptop.org/build-official_xo1.5-885/root/lib/firmware/sd8686* \
		"$output"/lib/firmware/
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the XO-1.5 firmware."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "(the XO-1.5 will have no network)  or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "sd8686* download failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		else 
			echo "Downloaded sd8686* . $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
		fi
		
	if [ "`ls $CWD/boot1* | grep '3\.3'`" != "" ] ; then
	if [ "`cat /tmp/avail_builds | grep 'xo1-36'`" = "" ] || [ "`cat /tmp/avail_builds | grep 'xo1.5-36'`" = "" ] ; then
		echo "The builds are not currently in the rsync server. "
		echo "Will take 5 to 10 minutes to be pulled in the server." 
		echo "Be patient..."
	fi
	# Get wireless firmware
	rsync -a rsync://updates.laptop.org/build-13.1.0_xo1-36/root/lib/firmware/libertas/usb8388* \
		"$output"/lib/firmware/libertas
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the XO-1 firmware."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "(the XO-1 will have no network)  or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "usb8388_olpc.bin download failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		else 
			echo "Downloaded usb8388_olpc.bin. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	rsync -a rsync://updates.laptop.org/build-13.1.0_xo1.5-36/root/lib/firmware/libertas/sd8686* \
		"$output"/lib/firmware/libertas
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the XO-1.5 firmware."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "(the XO-1.5 will have no network)  or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "sd8686_v9* download failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		else 
			echo "Downloaded sd8686_v9* . $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
		fi
	
		
	# Get the full version of rtcwake
	rsync -a rsync://updates.laptop.org/build-official_xo1-885/root/usr/sbin/rtcwake \
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

# Get specific pets (guvcview, sfs_load etc)
get_pets()
{
	# Create the output folder if not present 
	if [ ! -d $XO_sources/XO_sfs ] ; then 
		mkdir $XO_sources/XO_sfs
		output="$BASEDIR/XO_sfs"
	fi
	
	cd $output
	wget --trust-server-names http://www.murga-linux.com/puppy/viewtopic.php?mode=attach&id=43096
	tar xvzf guvcview*.pet
	cp -aR guvcview-1.4.5/usr/* usr/
	rm -rf guvcview-1.4.5*
}
export -f get_pets	

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
		if [ "$BLDCHROME" = "yes" ] && [ "$CORRECT" = "" ] && [ ! -d $BASEDIR/CHROME_DRIVER ] ; then
			echo -e "\\0033[1;31m"
			echo "However, it would appear you built chrome driver in another distro or pupplet"
			echo "Please rename $output/$DISTRO_FILE_PREFIX" 
			echo "to the appropriate \"DISTRO_FILE_PREFIX\"  for your target puppy NOW" 
			echo "so it will be included in your XO build." 
			echo "Then hit \"enter\" to continue"
			read CONTINUE 
			if [ "$CONTINUE" = "" ];then 
				echo -e "\\0033[1;34m"
				echo "OK"
			fi
		fi
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
			bld_chrome && fix_mod && finished ;; # && get_pets
-k|--kbdshim) check_dev && dnld_kbd && bld_kbd && fix_mod && finished ;;	
-p|--powerd) check_dev && dnld_powerd  && bld_powerd && fix_mod && finished ;;
-c|--chrome) check_dev && dnld_chrome && bld_chrome && fix_mod && finished ;; 
esac

		
