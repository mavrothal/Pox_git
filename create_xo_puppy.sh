#!/bin/bash
#a universal script to make an XO-1 and XO-1.5 compatible Puppy 
#from any woof (almost any) based Puppy Iso
#Please expand this outside of a pupsave if using Puppy.
#gpl3 (see /usr/share/doc) (c) mavrothal, 01micko
#NO WARRANTY

# bit of fun!
clear
echo "Welcome to Create XO Puppy"
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
VER=1.0

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
		-xh|--extended-help 	opens README.txt
		-i|--iso [path/to/isoname]	the full pathname of the Puppy iso
		-m|--manual [name of sfs]	the name of the Puppy main sfs file
		NOTE: with the -m option it is your responsibility
		to select the correct initrd.gz that matches the main
		.sfs and place both in the current directory
	
		(c) Created by mavrothal and 01micko
		@murga-linux puppy forum
		GPLv3. See /usr/share/doc/legal/
		NO WARRANTY
		While all care is taken NO responsibility is accepted
_USAGE
	
	xoolpcfunc
	exit 0
}
export -f usagefunc

case "$#" in
	0) usagefunc ;;
	[3-9])echo "too many arguments"; usagefunc ;;
esac

case $1 in 
	-h|--help) usagefunc && exit 0 ;;
	-v|--version) echo "$VER" && exit 0 ;;
	-xh|--extended-help)cat README.txt|more 
		xoolpcfunc && exit 0 ;;
	-i|--iso) [ ! $2 ] && usagefunc
		ISOPATH=$2 
		ISO="`basename $ISOPATH`" ;;
	-m|--manual) [ ! $2 ] && usagefunc
		ls $CWD|grep "^initrd" >/dev/null 2>&1
		echo -n initrd; statusfunc $?
		ININIT="`ls $CWD|grep "^initrd"`"
		INSFS="`ls $CWD|grep "sfs$"|head -n1`"
		echo "you chose $2"
		sleep 0.5
		echo "the sfs is $INSFS"
		sleep 0.5
		ls $CWD|grep "sfs$" >/dev/null 2>&1 
		echo -n $2; statusfunc $?
		[ "$2" != "$INSFS" ] && echo "ERROR: Not correct sfs.. typo?" && statusfunc 1
		;;
esac

#========================== Check and setup =================================
# test we are compatible Puppy #changed to any distro by mavrothal 110824
# put in a check for mksquashfs, ..Ubuntu doesn't ship with it. 110825 01micko
if [ -f /etc/DISTRO_SPECS ];then 
	. /etc/DISTRO_SPECS
else 
	MSQY="`which mksquashfs`"
	if [ "$MSQY" = "" ];then
		echo "Sorry, you cant run this $0 without \"$MSQY\""
		echo "Please install \"mksquashfs\" from your package manager"
		echo "and try again"
		statusfunc 1
	else
		echo "You are not running Puppy Linix"
		echo "This should be ok as it seems you have"
		echo "\"$MSQY\""
		echo "Hit enter to keep going"
		read getgoing
		statusfunc 0
	fi
fi

# test kernel for squash 4 support
KERNEL="`uname -r`"
KERNELMAJ="`echo $KERNEL|head -c1`"
KERNELMIN="`echo $KERNEL|cut -d '.' -f3`"
if [[ "$KERNELMAJ" -eq "2" && "$KERNELMIN" -ge "29" ]] || [[ "$KERNELMAJ" -eq "3" ]] ; then
	echo "kernel Ok"
	else echo "kernel too old, exiting" && exit 0
fi

# test for free space
BASEDISK="`echo $CWD|cut -d '/' -f 1,2,3`" #returns eg "/mnt/sda1"
BASEPART="`echo $CWD|cut -d '/' -f 3`" #returns eg "sda1" if not in pupsave
DF="`df -m|grep $BASEPART|awk '{print $4}'`"
# puppy specific
if [ -f /etc/DISTRO_SPECS ];then #puppy test only added 110825 01micko
	. /etc/rc.d/PUPSTATE
	if [[ "$PUPMODE" = "7" || "$PUPMODE" = "13" ]];then
	 echo "You have a USB install to slow media and this program"
	 echo "will fail if you try to run it on the usb media"
	 echo "make absolutely sure you run this in a linux filesystem on a HDD"
	 echo "or if you have over a gigabyte of RAM, make a ramdisk .."
	 echo "...for advanced users only!"
	 echo "Hit enter to continue"
	 read goon
	fi
# cheat!
	if [ "`echo $BASEDISK|grep "root"`" != "" ];then 
	 DF="`cat /tmp/pup_event_sizefreem`"
	fi
fi
if test "$DF" -lt "500" ;then EXIT=1
	echo "space check... disk space free is $DF"
	echo "...not enough space, do this on another partiton"
		else EXIT=0
	echo "space check... disk space free is $DF"
fi
statusfunc $EXIT

# set vars
XODIR="$CWD"
[ ! -d $XODIR/squashdir/squashfs-root ] && mkdir -p $XODIR/squashdir/squashfs-root
SQDIR="$XODIR/squashdir"
SFSROOT="$SQDIR/squashfs-root"
INITDIR="$XODIR"
XOSFS="$XODIR/XO_sfs"
extra_pets="$XODIR/extra_pets"
MNTDIR=""

#========================= Get files from iso ===============================
if [ "$ISOPATH" != "" ];then 
	[ ! -d  $CWD/mntiso ] && mkdir $CWD/mntiso
	MNTDIR="$CWD/mntiso"
	echo "mounting $ISO"
	mount $ISOPATH $MNTDIR -o loop
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
	cp initrd* $INITDIR
	cd ..
	sync
	umount $MNTDIR
	rm -rf $MNTDIR
	sync
fi

#============================= mod main sfs ================================== 
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

# T2 builds do not have the full udev with extras and the synaptics 
# driver freezes the mouse/keyboard in the XO-1.5. Get them.
. $SFSROOT/etc/DISTRO_SPECS
case "$DISTRO_FILE_PREFIX" in
wary|racy|luki|lina|arch) 
	if [ ! -f $extra_pets/udev_luki_racy-167-i486.pet ] ; then 
		wget -c -P $extra_pets\
	http://ftp.cc.uoc.gr/mirrors/linux/XOpup/XOpets/udev_luki_racy-167-i486.pet
		if [ $? -ne 0 ]; then
			echo "Failed to download udev.pet. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			echo "The T2 udev.pet was added in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	else 
		echo "The T2 udev.pet was in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	if [ "$DISTRO_FILE_PREFIX" = "luki" ] ; then
		if [ ! -f $extra_pets/jwm-578-deco-luki-2-i486.pet ] ; then 
			wget -c -P $extra_pets\
	http://ftp.cc.uoc.gr/mirrors/linux/XOpup/XOpets/jwm-578-deco-luki-2-i486.pet
			if [ $? -ne 0 ]; then
				echo "Failed to download jwm-578-deco-luki-2-i486.pet. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				echo "The jwm-578-deco-luki-2-i486.pet was added in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fi
		else 
			echo "The jwm-578-deco-luki-2-i486.pet was in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	fi
	if [ "$DISTRO_FILE_PREFIX" = "arch" ] ; then
		if [ ! -f $extra_pets/archdialogs-1.pet ] ; then 
			wget -c -P $extra_pets\
	http://ftp.cc.uoc.gr/mirrors/linux/XOpup/XOpets/archdialogs-1.pet
			if [ $? -ne 0 ]; then
				echo "Failed to download archdialogs-1.pet. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				echo "The archdialogs-1.pet was added in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fi
		else 
			echo "The archdialogs-1.pet was in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	fi
	;;
slacko)
	if [ "$DISTRO_COMPAT_VERSION" = "14.0" ] ; then
		if [ ! -f $extra_pets/udev-175-i486.pet ] ; then 
			wget -c -P /tmp \
			http://ftp.cc.uoc.gr/mirrors/linux/XOpup/XOpets/udev-175_Slacko14.tar.gz
			if [ $? -ne 0 ]; then
				echo "Failed to download udev-175. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				sync
				tar xvzf /tmp/udev-175_Slacko14.tar.gz -C /tmp/
				cp /tmp/udev-175_Slacko14/udev-175-i486.pet $extra_pets/
				rm -rf /tmp/udev-175_Slacko14*
				sync
				echo "udev-175-i486.pet for slacko was added in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fi
		else 
			echo "udev-175-i486.pet for slacko  was in the extra_pets folder. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	fi
	;;
*)  
	echo "Nothing special"
	;;
esac

# Include extra pets in the build 
# Do it early in case pets have unneeded components
if [ "`ls $extra_pets | grep '.pet'`" = "" ] ; then
	echo -e "\\0033[1;34m"
	echo "If you want any additional pets in the build"
	echo "add them NOW in the \"extra_pets\" folder and then"
	echo "hit \"a\"  and then  \"enter\" to continue"
	echo "or just \"enter\" to skip this step."
	echo -en "\\0033[0;39m"
	read CONTINUE
		if [ "$CONTINUE" = "a" ];then
			echo "including the following pets in the build
`ls $extra_pets`"
			echo "The following pets were included in the build" >> $CWD/build.log
			cd $extra_pets
			for p in ./* 
				do 
				PNAME=`echo $p | sed 's/\.pet//'`
				tar xzf $p 2>/dev/null 
				cd $PNAME
				cat *.spec* >> $SFSROOT/root/.packages/woof-installed-packages
				rm -f *.sh *.spec* 2>/dev/null
				find . > /tmp/$PNAME.files
				PREVPATH=''
				cat /tmp/$PNAME.files |
				while read ONELINE
				do
				if [ -d "${ONELINE}" ] ; then
					PREVPATH="$ONELINE"
					echo "$ONELINE" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
				else
					NEWPATH="`dirname "$ONELINE"`"
					[ "$NEWPATH" == "/" ] && continue #ignore top-level files.
					NEWFILE="`basename "$ONELINE"`"
					if [ -e "${ONELINE}" ] ; then #sanity check.
						if [ "$PREVPATH" == "$NEWPATH" ] ; then #sanity check.
							echo " ${NEWFILE}" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
						fi
					fi
				fi
				done					
				cp -aR * $SFSROOT
				if [ $? -ne 0 ]; then
					echo "Failed to add $p in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				else
					echo "$p was added in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				fi
				cd $extra_pets 
				rm -rf $PNAME
				rm -f /tmp/"$PNAME".files
				sed -i 's/^\.//' $SFSROOT/root/.packages/builtin_files/$PNAME
			done
		fi
else
	echo  "including the following pets in the build
`ls $extra_pets`"
	echo "The following pets were included in the build" >> $CWD/build.log
	cd $extra_pets
	for p in ./* 
		do 
		PNAME=`echo $p | sed 's/\.pet//'`
		tar xzf $p 2>/dev/null 
		cd $PNAME
		cat *.spec* >> $SFSROOT/root/.packages/woof-installed-packages
		rm -f *.sh *.spec* 2>/dev/null
		find . > /tmp/$PNAME.files
		PREVPATH=''
		cat /tmp/$PNAME.files |
		while read ONELINE
		do
		if [ -d "${ONELINE}" ] ; then
			PREVPATH="$ONELINE"
			echo "$ONELINE" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
		else
			NEWPATH="`dirname "$ONELINE"`"
			[ "$NEWPATH" == "/" ] && continue #ignore top-level files.
			NEWFILE="`basename "$ONELINE"`"
			if [ -e "${ONELINE}" ] ; then #sanity check.
				if [ "$PREVPATH" == "$NEWPATH" ] ; then #sanity check.
					echo " ${NEWFILE}" >> $SFSROOT/root/.packages/builtin_files/"$PNAME"
				fi
			fi
		fi
		done					
		cp -aR * $SFSROOT
		if [ $? -ne 0 ]; then
			echo "Failed to add $p in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		else
			echo "$p was added in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
		cd $extra_pets 
		rm -rf $PNAME
		rm -f /tmp/"$PNAME".files
		sed -i 's/^\.//' $SFSROOT/root/.packages/builtin_files/$PNAME
	done
fi

# Check if we include a service pack pet so we update DISTRO_SPECS on the initrd
SERVPACK="`ls $extra_pets | grep service_pack`"
if [ "$SERVPACK" != "" ] ; then 
	. $SFSROOT/etc/DISTRO_SPECS
fi

cd $SQDIR
# delete old kernel
rm -rf $SFSROOT/lib/modules/* 
echo "deleting old kernel"
# delete not needed firmware
rm -rf $SFSROOT/lib/firmware/* 
echo "deleting not needed firmware"

echo "removing unneeded xorg drivers"

# Sort video drivers
# We can compile more drivers for separate distro and store in
# drake, wary, squezze, lupu whatever dir
case "$DISTRO_FILE_PREFIX" in
wary|racy|luki|lina)   XORGDIR="$SFSROOT/usr/X11R7/lib/xorg/modules/drivers" 
		XORGLIBDIR="$SFSROOT/usr/X11R7/lib/"	
		cp -af $XODIR/{wary,racy,luki,lina,CHROME_DRIVER}/xorg/modules/drivers/* \
		$SFSROOT/usr/X11R7/lib/xorg/modules/drivers/
		;; 
*) 
		XORGDIR="$SFSROOT/usr/lib/xorg/modules/drivers"
		XORGLIBDIR="$SFSROOT/usr/lib/"
		cp -af $XODIR/{"$DISTRO_FILE_PREFIX",CHROME_DRIVER}/xorg/modules/drivers/* \
		$SFSROOT/usr/lib/xorg/modules/drivers/ 
		;;		
esac

XMODULES="`ls $XORGDIR \
	|grep -iE -v "chrome|geode|openchrome|sisusb|ztv_drv|v4l"`"

# remove unneeded xorg drivers #are they right?
for drv in $XMODULES
do 
	rm -f $XORGDIR/$drv
 	echo "removing $drv"
done
# some puppies have additonal drivers elsewhere
rm -rf $SFSROOT/usr/lib/xorg/modules/drivers-*
rm -rf $SFSROOT/usr/lib/x/*

# Remove synaptics driver 
rm -f $SFSROOT/usr/lib/xorg/modules/input/synaptics_drv.so
rm -f $SFSROOT/usr/X11R7/lib/xorg/modules/input/synaptics_drv.so

# Check if we have the XO-1 geode video driver. Older puppies don't
if [ "`ls $XORGDIR | grep geode`" = "" ] ; then
	echo -e "\\0033[1;31m"
	echo "You do not have the geode video driver. Your build will NOT "
	echo "run on the XO-1.  Hit \"x\"  and then  \"enter\" to exit"
	echo "or just \"enter\" to continue and try to built it"
	echo -en "\\0033[0;39m"
	read CONTINUE
	if [ "$CONTINUE" = "x" ];then
		rm -rf $SQDIR
		rm -f $XODIR/initrd.gz
		echo "No geode driver. Build aborted. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		exit 1
	else
		echo -e "\\0033[1;34m"
		echo "Do you want to try to compile the geode video driver now? "
		echo "WARNING. The build will be aborted if it fails."
		echo ""
		echo "Hit \"c\"  and then  \"enter\" to compile it"
		echo "or just \"enter\" to continue without it"
		echo -en "\\0033[0;39m"
		read CONTINUE	
		if  [ "$CONTINUE" = "c" ];then
			cd $XODIR/XO_SFS_sources
			wget -c http://xorg.freedesktop.org/releases/individual/driver/xf86-video-geode-2.11.13.tar.gz
			if [ $? -ne 0 ]; then
				echo -e "\\0033[1;31m"
				echo "Error: failed to download the geode driver source"
				echo "Check the connection and try again"
				echo -en "\\0033[0;39m"
				echo "Failed to dowanload the geode driver source. Aborting build $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				exit 1
			fi
			sync
			tar xvzf xf86-video-geode-2.11.13.tar.gz
			sync
			rm -f xf86-video-geode-2.11.13.tar.gz
			cd xf86-video-geode-2.11.13
			./configure
			sync
			make
			if [ $? -ne 0 ]; then
				echo "Geode compilation failed. Aborting build." >> $CWD/build.log
				echo "Try co compile from within the  xf86-video-geode-2.11.13 directory. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				exit 1
			else
				echo "geode_drv.so was compiled successfully. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fi
			strip -s src/.libs/*.so
			cp -a src/.libs/*.so $XORGDIR 
			cp -a src/.libs/*.so $XODIR/$DISTRO_FILE_PREFIX/xorg/modules/drivers # keep for futre builds
			sync
			make clean 
			cd $SQDIR
		else
			echo "WARNING No geode driver. The build will NOT run on the XO-1. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	fi
fi

echo "removing other useless stuff for XO..."
# remove extra video stuff
echo "extra video libs..."
for v in $XTRA 
do 
	echo "removing $v"
 	rm -f $XORGLIBDIR/$v
done
# remove puppy scripts
echo "unneeded puppy scripts..." 
cd $SFSROOT 
for s in $WOOFSCRIPTS
do  
	echo "removing $s"
 	rm -f usr/sbin/$s
done
 
for i in $OTHER
do  
	echo "removing $i"
 	rm root/Startup/$i
done

# ...and DOT desktops
echo "unneeded .desktop files..." 
for desk in $WOOFDESK
do 
	echo "removing $desk"
 	rm -f usr/share/applications/$desk
done 

# Remove xcalc
rm -f usr/bin/xcalc

# Patch xorgwizard
patches="$CWD/XO_sfs_patches"
echo "patching xorgwizrd"
if [ "$DISTRO_FILE_PREFIX" = "lupu" ]; then
	echo "patching xorgwizrd.sh"
	patch -p1 < $patches/xorgwizard.sh.patch
	if [ $? -ne 0 ]; then
		echo "Failed to patch xorgwizard.sh. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/xorgwizard.sh.rej
	mv -f usr/sbin/xorgwizard.sh.orig usr/sbin/xorgwizard.sh
	else
		echo "Patched xorgwizard.sh. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		rm -f usr/sbin/xorgwizard.sh.orig
	fi

else

patch -p1 < $patches/xorgwizard.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch xorgwizard. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/xorgwizard.rej
	mv -f usr/sbin/xorgwizard.orig usr/sbin/xorgwizard
	# New woof uses gettext in scripts so old patches may not work fully
	patch -p1 < $patches/xorgwizard_lng.patch
	if [ $? -ne 0 ]; then
		echo "Failed to patch xorgwizard with _lng patch too. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		rm -f usr/sbin/xorgwizard.rej
		mv -f usr/sbin/xorgwizard.orig usr/sbin/xorgwizard
		# some puppies have xorg-setup instead
		patch -p1 usr/sbin/xorg-setup < $patches/xorgwizard.patch
		if [ $? -ne 0 ]; then
			echo "Failed to patch xorg-setup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			rm -f usr/sbin/xorg-setup.rej
			mv -f usr/sbin/xorg-setup.orig usr/sbin/xorg-setup
		else
			echo "Patched xorg-setup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			rm -f usr/sbin/xorg-setup.orig
		fi
	else
		echo "Patched xorgwizard with _lng patch. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log	
		rm -f usr/sbin/xorgwizard.orig	
	fi
else
	echo "Patched xorgwizard. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/xorgwizard.orig
fi

fi

# Patch snapmerge
echo "patching snapmergepuppy"
patch -p1 < $patches/snapmerge.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch snapmergepuppy. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/snapmergepuppy.rej
	mv -f usr/sbin/snapmergepuppy.orig usr/sbin/snapmergepuppy
else
	echo "Patched snapmergepuppy. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/snapmergepuppy.orig
fi

# Patch frontend_d
echo "patching pup_event_frontend_d"
patch -p1 < $patches/frontend_d.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch pup_event_frontend_d. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f sbin/pup_event_frontend_d.rej
	mv -f sbin/pup_event_frontend_d.orig sbin/pup_event_frontend_d
else
	echo "Patched pup_event_frontend_d. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f sbin/pup_event_frontend_d.orig
fi

# Patch rc.shutdown
echo "patching rc.shutdown"
patch -p1 < $patches/rc.shutdown.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch rc.shutdown. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f etc/rc.d/rc.shutdown.rej
	mv -f etc/rc.d/rc.shutdown.orig etc/rc.d/rc.shutdown
else
	echo "Patched rc.shutdown. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f etc/rc.d/rc.shutdown.orig
fi

# Patch rc.shutdown so will not hung in "save to partition" installs.
echo "patching rc.shutdown"
patch -p1 < $patches/rc.shutdown2.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch rc.shutdown for SAVE TO PARTITION. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f etc/rc.d/rc.shutdown.rej
	mv -f etc/rc.d/rc.shutdown.orig etc/rc.d/rc.shutdown
else
	echo "Patched rc.shutdown for SAVE TO PARTITION. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f etc/rc.d/rc.shutdown.orig
fi

# Patch dotpup
echo "patching dotpup"
patch -p1 < $patches/dotpup.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch dotpup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/dotpup.rej
	mv -f usr/sbin/dotpup.orig usr/sbin/dotpup
else
	echo "Patched dotpup. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/dotpup.orig
fi

# add /run and /run/udev directories for newer udev and didtros
mkdir -p tmp/udev
ln -sf tmp run


# Remove xload from tray. Wastes CPU cycles
echo "removing xload from tray"
case "$DISTRO_FILE_PREFIX" in
slacko)
	patch -p1 < $patches/jwmrc-tray_slacko.patch
	if [ $? -ne 0 ]; then
		patch -p1 < $patches/jwmrc-tray_slacko2.patch
		if [ $? -ne 0 ]; then
			echo "Failed to patch jwmrc-tray. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			rm -f root/.jwmrc-tray.rej
			mv -f root/.jwmrc-tray.orig root/.jwmrc-tray
		else
			echo "Patched jwmrc-tray. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			rm -f root/.jwmrc-tray.orig
		fi
	fi
	;;
*)
	patch -p1 < $patches/jwmrc-tray.patch
	if [ $? -ne 0 ]; then
		echo "Failed to patch jwmrc-tray. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		rm -f root/.jwmrc-tray.rej
		mv -f root/.jwmrc-tray.orig root/.jwmrc-tray
	else
		echo "Patched jwmrc-tray. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		rm -f root/.jwmrc-tray.orig
	fi
	;;
esac

# Add support for the XO internal drives in fstab
echo "Adjusting /etc/fstab for XO internal drives..."
cat << EOF >> $SFSROOT/etc/fstab
/dev/mtdblock0		/.xo-nand	jffs2	defaults,noauto	  0 0
/dev/mmcblk1p2		/.intSD	    ext4	defaults,noauto	  0 0
EOF

# Stop cups and other services
chmod 644 $SFSROOT/etc/init.d/cups
chmod 644 $SFSROOT/etc/init.d/start_cpu_freq
chmod 644 $SFSROOT/etc/init.d/usb-modeswitch

# Fix menu font size, in Seamonkey/Firefox
sed -i 's/font-size: 12px !important;/font-size: 16px !important;/' \
 $SFSROOT/root/.mozilla/{seamonkey,firefox}/*.default/chrome/userChrome.css
 
# Fix JWM window tittle hight
sed -i 's/Height>[0-9][0-9]/Height>30/' $SFSROOT/root/.jwm/jwmrc-theme 
sed -i 's/Height>[0-9][0-9]/Height>30/' $SFSROOT/root/.jwmrc
sed -i 's/Height>[0-9][0-9]/Height>30/' $SFSROOT/etc/xdg/templates/_root_.jwmrc
sed -i 's/WINDOWHEIGHT="[0-9][0-9]"/WINDOWHEIGHT="30"/' $SFSROOT/etc/JWMRC
sed -i 's/WINDOWHEIGHT="[0-9][0-9]"/WINDOWHEIGHT="30"/' $SFSROOT/root/.jwm/JWMRC
for i in $SFSROOT/root/.jwm/themes/*-jwmrc 
	do 
		sed -i 's/Height>[0-9][0-9]/Height>30/' $i  
	done

# Make JWM windows decoration and clock fonts bigger
sed -i "s/<\/JWM>//" $SFSROOT/root/.jwm/jwmrc-personal
cat << EOF >> $SFSROOT/root/.jwm/jwmrc-personal

   <!-- window buttons -->
   <ButtonClose>/usr/share/pixmaps/close.xbm</ButtonClose>
   <ButtonMax>/usr/share/pixmaps/max.xbm</ButtonMax>
   <ButtonMaxActive>/usr/share/pixmaps/maxact.xbm</ButtonMaxActive>
   <ButtonMin>/usr/share/pixmaps/min.xbm</ButtonMin>
   
   <ClockStyle>
 	 <!--Background>#000000</Background-->
 	 <Font>Sans-13:bold</Font>
 	 <!--Foreground>#00DB2C</Forground-->
   </ClockStyle>

</JWM>
EOF

# Remove JWM Submenus
sed -i '0,/0/s/0//' $SFSROOT/root/.jwm/JWMRC

# Add support for JWM second tray if we installed it
if [ -f $SFSROOT/usr/local/jwmconfig2/app_tray_config ] ; then
	sed -i "s/<\/JWM>//" $SFSROOT/root/.jwm/jwmrc-personal
	cat << EOF >> $SFSROOT/root/.jwm/jwmrc-personal
	
	<Include>/root/.jwmrc-tray2</Include>
	
</JWM>
EOF

	cat << EOF > $SFSROOT/root/.jwmrc-tray2
<JWM>
<Tray autohide="true"  insert="right" halign="center" x="-1" y="0" border="2" height="48" layout="horizontal" >
<!-- Additional TrayButton attribute: label -->
<TrayButton popup="File browser" icon="home48.png">exec:rox</TrayButton>
<TrayButton popup="Web Browser" icon="www48.png">exec:defaultbrowser</TrayButton>
<TrayButton popup="Text editor" icon="edit48.png">exec:defaulttexteditor</TrayButton>
<TrayButton popup="Media Player" icon="multimedia48.png">exec:defaultmediaplayer</TrayButton>
<TrayButton popup="Word processor" icon="word48.png">exec:defaultwordprocessor</TrayButton>
<TrayButton popup="Screen capture" icon="mini-camera.xpm">exec:mtpaintsnapshot.sh</TrayButton>
<TrayButton popup="XArchive archiver" icon="archive48.png">exec:xarchive</TrayButton>
<TrayButton popup="Terminal" icon="console48.png">exec:urxvt</TrayButton>
<TrayButton popup="Puppy Package Manager" icon="pet48.png">exec:/usr/local/petget/pkg_chooser.sh</TrayButton>
<TrayButton popup="Configure your puppy" icon="configuration48.png">exec:wizardwizard</TrayButton>
</Tray>
</JWM>
EOF
fi

# Fix driver spacing to fit SDcard long name
sed -i 's/ICON_PLACE_SPACING=[0-9][0-9]/ICON_PLACE_SPACING=108/' $SFSROOT/etc/eventmanager

# Check if we installed original Frisbee and make it default
if [ "`ls $extra_pets | grep Frisbee`" != "" ] ; then
	if [ "`cat $SFSROOT/usr/sbin/connectwizard_2nd | grep '/bin/frisbee'`" != "" ] ; then
		sed -i 's/frisbee/Frisbee/g' $SFSROOT/usr/sbin/connectwizard_2nd
		sed -i 's/frisbee/Frisbee/g' $SFSROOT/usr/sbin/connectwizard
		#This should not be necessary but somehow connectwizard_2nd needs
		#a Frisbee "network restart" to set it as a defaultconnect :-? 
		#Is still problematic even with this hack
		cat << EOF > $SFSROOT/usr/local/bin/defaultconnect
#!/bin/sh
exec Frisbee
EOF
	else
		chmod 000 $SFSROOT/root/Startup/network_tray
		cat << EOF > $SFSROOT/usr/local/bin/defaultconnect
#!/bin/sh
exec Frisbee
EOF

		# ...and patch connectwizard_2nd
		echo "patching connectwizard_2nd for Frisbee"
		patch -p1 < $patches/connectwizard_2nd.patch
		if [ $? -ne 0 ]; then
			echo "Failed to patch connectwizard_2nd for Frisbee. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			rm -f usr/sbin/connectwizard_2nd.rej
			mv -f usr/sbin/connectwizard_2nd.orig usr/sbin/connectwizard_2nd
		else
			echo "Patched connectwizard_2nd for frisbee. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			rm -f usr/sbin/connectwizard_2nd.orig
		fi
	fi
fi

#Set frisbee-1.0 to autostart WiFi (till the default is changed).
if [ -f $SFSROOT/usr/bin/frisbee ] ; then
	touch $SFSROOT/etc/frisbee/.wireless_autostart
fi	
#============================= Pupplet specific fixes ========================
case "$DISTRO_FILE_PREFIX" in

slacko)
# Change pager width
sed -i "s/"maxwidth=\"25\""/"maxwidth=\"0\""/" $SFSROOT/root/.jwmrc-tray

if [ "$DISTRO_COMPAT_VERSION" = "13.37" ] ; then
	# Fix quickpet sfs list.
	# Careful. Is kernel specific
	KER1=`ls $XODIR/boot10 | grep config | sed 's/config-//'`
	KER15=`ls $XODIR/boot15 | grep config | sed 's/config-//'`
	cd $SFSROOT/etc/quickpet
	ln -sf Sfs-puppy-spup-official-2.6.37.6 Sfs-puppy-spup-official-"$KER1"
	ln -sf Sfs-puppy-spup-official-2.6.37.6 Sfs-puppy-spup-official-"$KER15"
	cd $SFSROOT
fi

if [ "$DISTRO_COMPAT_VERSION" = "14.0" ] ; then
	rm -f $SFSROOT/puninstall.sh
	#Part of the 'BUG' hack in slacko. We do not need it and messes up kernver
	sed -i '/^KERNVER=\$/d' $SFSROOT/etc/rc.d/rc.sysinit
fi
;;

luki|lina)
# Fix font size for XFCE4 (Saluki 006+/Calorina 001+)
sed -i 's/<property name="DPI" type="empty"\/>/<property name="DPI" type="int" value="140"\/>/' $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
sed -i 's/<\/channel>//' $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
cat << EOF >> $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
  <property name="Xfce" type="empty">
    <property name="LastCustomDPI" type="int" value="140"/>
  </property>
</channel>
EOF
sed -i 's/Bold,14/Bold,11/' $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
sed -i 's/24/32/' $SFSROOT/root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
sed -i 's/16/11/' $SFSROOT/root/.config/Terminal/terminalrc
sed -i 's/Droid Sans 12/Droid Sans 10/' $SFSROOT/root/.gtkrc-2.0

# Patch frontend_d which differs in Saluki
echo "patching pup_event_frontend_d"
patch -p1 < $patches/frontend_d-luki.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch pup_event_frontend_d in Saluki. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f sbin/pup_event_frontend_d.rej
	mv -f sbin/pup_event_frontend_d.orig sbin/pup_event_frontend_d
else
	echo "Patched pup_event_frontend_d in Saluki. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f sbin/pup_event_frontend_d.orig
fi

# Fix the suspend/hibernate calls (Saluki)
sed -i 's/\/etc\/acpi\/hibernate\.sh/powerd-config =gotosleep/' $SFSROOT/usr/bin/shutdown-gui
sed -i 's/\/etc\/acpi\/sleep\.sh/powerd-config =dark-suspend/' $SFSROOT/usr/bin/shutdown-gui

# Add support for the XO internal drives in fstab
cat << EOF >> $SFSROOT/etc/fstab.d/static_entries
/dev/mtdblock0		/.xo-nand	jffs2	defaults,noauto	  0 0
/dev/mmcblk1p2		/.intSD	    ext4	defaults,noauto	  0 0
EOF

# Further increase font size
sed -i 's/108/130/' $XOSFS/root/.Xresources
;;
luki)
#Fix JWM 
echo "patching jwmrc"
patch -p1 < $patches/jwmrc.patch
if [ $? -ne 0 ]; then
	echo "Failed to Patch jwmrc. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f root/.jwmrc.rej
	mv -f root/.jwmrc.orig root/.jwmrc
else
	echo "Patched jwmrc. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f root/.jwmrc.orig
fi
patch -p1 < $patches/etc_jwmrc.patch
if [ $? -ne 0 ]; then
	echo "Failed to Patch _root_.jwmrc. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f etc/xdg/templates/_root_.jwmrc.rej
	mv -f etc/xdg/templates/_root_.jwmrc.orig etc/xdg/templates/_root_.jwmrc
else
	echo "Patched _root_.jwmrc. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f etc/xdg/templates/_root_.jwmrc.orig
fi

cat << EOF > $SFSROOT/usr/sbin/variconlinks_luki
#!/bin/bash

DIR=\`pwd\`

rm -rf /var/local/icons
mkdir /var/local/icons

ln -fs /usr/share/icons/hicolor/16x16/apps/* /var/local/icons/ 2>/dev/null
ln -fs /usr/share/icons/hicolor/22x22/apps/* /var/local/icons/ 2>/dev/null
ln -fs /usr/share/icons/hicolor/24x24/apps/* /var/local/icons/ 2>/dev/null
ln -fs /usr/share/icons/hicolor/32x32/apps/* /var/local/icons/ 2>/dev/null
ln -fs /usr/share/icons/hicolor/48x48/apps/* /var/local/icons/ 2>/dev/null
ln -fs /usr/share/icons/hicolor/48x48/devices/* /var/local/icons/ 2>/dev/null
ln -fs /usr/share/pixmaps/abiword.png /var/local/icons/ 2>/dev/null


cd /var/local/icons
ls | grep xpm | while read FILE
do
FILE2=\`echo "\$FILE" | sed 's/.xpm//'\`
ln -s "\$FILE" "\$FILE2" 2>/dev/null
done
ls | grep png | while read FILE
do
FILE2=\`echo "\$FILE" | sed 's/.png//'\`
ln -s "\$FILE" "\$FILE2" 2>/dev/null
done

cd "\$DIR"
exit 0
EOF
chmod 755 $SFSROOT/usr/sbin/variconlinks_luki

# Patch fixmenus to use variconlinks_luki
patch -p1 < $patches/fixmenus.patch
if [ $? -ne 0 ]; then
	echo "Failed to Patch fixmenus for Saluki . $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/fixmenus.rej
	mv -f usr/sbin/fixmenus.orig usr/sbin/fixmenus
else
	echo "Patched fixmenus for Saluki. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/sbin/fixmenus.orig
fi

#Add pmount in the tray
patch -p1 < $patches/jwmrc-tray_luki.patch
if [ $? -ne 0 ]; then
	echo "Failed to Patch .jwmrc-tray for Saluki . $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f root/.jwmrc-tray.rej
	mv -f root/.jwmrc-tray.orig root/.jwmrc-tray
else
	echo "Patched .jwmrc-tray for Saluki. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f root/.jwmrc-tray.orig
fi

# reload instead of restart JWM
sed -i "s/jwm -restart/jwm -reload/" $SFSROOT/usr/local/petget/installpreview.sh 
sed -i "s/jwm -restart/jwm -reload/" $SFSROOT/usr/local/petget/removepreview.sh  
sed -i "s/jwm -restart/jwm -reload/" $SFSROOT/usr/local/petget/petget 

# Show file/folder icons in Thunar when in JWM
echo "patching xwin"
patch -p1 < $patches/xwin.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch xwin. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/bin/xwin.rej
	mv -f usr/bin/xwin.orig usr/bin/xwin
else
	echo "Patched xwin. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f  usr/bin/xwin.orig
fi

# Add a second JWM tary on top
cat << EOF > $SFSROOT/root/.jwmrc-tray2
<JWM>
<Tray autohide="true"  insert="right" halign="center" x="-1" y="0" border="2" height="54" layout="horizontal" >
<!-- Additional TrayButton attribute: label -->
<TrayButton popup="File browser" icon="home48.png">exec:Thunar</TrayButton>
<TrayButton popup="Web Browser" icon="www48.png">exec:defaultbrowser</TrayButton>
<TrayButton popup="Terminal" icon="xfce-terminal.png">exec:Terminal</TrayButton>
<TrayButton popup="Geany text editor" icon="edit48.png">exec:geany</TrayButton>
<!--TrayButton popup="PDF viewer" icon="evince.png">exec:evince</TrayButton-->
<Program label="mtPaint image editor" icon="paint48.png">exec:mtpaint</Program>
<TrayButton popup="XArchive archiver" icon="pupzip.png">exec:xarchive</TrayButton>
<TrayButton popup="Puppy Package Manager" icon="pet.png">exec:/usr/local/petget/pkg_chooser.sh</TrayButton>
<TrayButton popup="SFS-Load on-the-fly" icon="squashfs-image.png">exec:sfs_load</TrayButton>
<TrayButton popup="Control Panel" icon="configuration24.png">exec:wizardwizard</TrayButton>
<!--TrayButton popup="Frisbee connect to internet" icon="frisbee.png">exec:Frisbee</TrayButton-->
<TrayButton popup="Shutdown" icon="shutdown.png">exec:shutdown-gui</TrayButton>
</Tray>
</JWM>
EOF
;;
precise)
# Remove puminstall from the root of the sfs
rm -f $SFSROOT/puninstall.sh
# Remove libLLVM
rm -f $SFSROOT/usr/lib/libLLVM*
;;
arch)
# Fix xorg for XO-1.5
cat << EOF >$SFSROOT/usr/local/share/xorg_1.5_arch

Section "Monitor"
       Identifier       "LCD"
       Option  "PanelSize"     "1200x900"
       DisplaySize 152 114
       VertRefresh 49-51 
       Option "DiPort" "DFP_HIGHLOW,DVP1"
EndSection
	
Section "Modes"
	Identifier "Modes0"
	#modes0modeline0
EndSection

Section "Device"
	#BusID       "PCI:0:1:0"
	Driver      "chrome"
	VendorName  "VIA Tech"
	BoardName   "VX855"
    Identifier      "Configured Video Device"
    # Option "MigrationHeuristic" "greedy"
    # Option "SWCursor"
EndSection

Section "Screen"
	Identifier "Screen0"
	Device     "Card0"
	Monitor    "Monitor0"
	DefaultDepth 24
	#Option         "metamodes" "1200x900_60 +0+0" #METAMODES_0
	Subsection "Display"
		Virtual     1200 1200
		Depth       24
		Modes       "1200x900"
	EndSubsection
EndSection

EOF

patch -p1 < $patches/archpupx.patch
if [ $? -ne 0 ]; then
	echo "Failed to patch archpupx. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/bin/archpupx.rej
	mv -f usr/bin/archpupx.orig etc/rc.d/archpupx
else
	echo "Patched archpupx. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	rm -f usr/bin/archpupx.orig
fi


# Add XO apps in start and fix .start
sed -i '/^conky/d' $SFSROOT/root/.start
sed -i '/^numlockx/d' $SFSROOT/root/.start
sed -i '/^rdate/d' $SFSROOT/root/.start
sed -i '/^exit/d' $SFSROOT/root/.start
cat << EOF >> $SFSROOT/root/.start
for i in `ls /root/Startup`
do 
 exec /root/Startup/$i &
 sleep 0.5s 
done
rdate -s tick.greyware.com &
exit

EOF

#Fix conky if we do not use it be default ;)
sed -i 's/eth0/wlan0/g' $SFSROOT/root/.conkyrc

# Remove custom puppy Xdefaults/Xresources. Fix Xdefaults
rm -f $XOSFS/root/.X*
sed -i 's/17/19/' $SFSROOT/root/.Xdefaults
sed -i 's/86/108/' $SFSROOT/root/.Xdefaults

# Remove udev-175 libudev
rm -f $SFSROOT/lib/libudev.so.0.13.0
echo "ln -sf /lib/libudev.so.0.11.1 /lib/libudev.so.1" >> $XOSFS/etc/rc.d/rc.local
;;
*) echo "Nothing Special" ;;
esac


statusfunc 0

#========================= Remove/move packages ==============================

echo "The following buildin packages have been removed from the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
for i in $PACKAGES_REM
	do 
	D="$SFSROOT/root/.packages/builtin_files"
	PKG=$i
	FILES="`cat $D/$PKG`"
	if [ -f $D/$PKG ] ; then
		echo "removing \"$i\""
		for LINE in $FILES
			do
			if [ "`echo $LINE|head -c1`" = "/" ];then
				x=`echo $LINE|sed 's%^\/%%'`
				cd $SFSROOT/$x
			else
				x="$LINE"
				rm $x
			fi
			done
			# fix root/.packages/woof-installed-packages
		grep -v "$PKG" $SFSROOT/root/.packages/woof-installed-packages| \
			while read LINE
				do 
				echo $LINE >> $SFSROOT/root/.packages/woof-installed-packages.tmp
				done
		mv -f $SFSROOT/root/.packages/woof-installed-packages.tmp \
			$SFSROOT/root/.packages/woof-installed-packages		 
		rm $D/$PKG 
		if [ $? -ne 0 ]; then
			echo "Failed to remove $PKG from the build." >> $CWD/build.log
		else
			echo "$PKG was removed." >> $CWD/build.log
		fi
		statusfunc $?
	fi
	done

cd $SQDIR

echo -e "\\0033[1;34m"
echo "Do you want to move some, not frequently used on the XO,"
echo "applications to an \"extras.sfs\" ? "
echo "Hit \"m\"  and then  \"enter\" to move them"
echo "or just \"enter\" to skip this step."
echo -en "\\0033[0;39m"
read CONTINUE
if [ "$CONTINUE" = "m" ];then
	echo "The following buildin packages have been moved into the extras.sfs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	mkdir -p $SQDIR/extras
	for i in $PACKAGES_MOVE
		do 
		D="$SFSROOT/root/.packages/builtin_files"
		PKG=$i
		FILES="`cat $D/$PKG`"
		if [ -f $D/$PKG ] ; then
			echo "moving \"$i\""
			for LINE in $FILES
				do
				if [ "`echo $LINE|head -c1`" = "/" ];then
					mkdir -p $SQDIR/extras"$LINE"
					MOVEPATH=$SQDIR/extras"$LINE"/
					x=`echo $LINE|sed 's%^\/%%'`
					cd $SFSROOT/$x
				else
					x="$LINE"
					mv -f $x $MOVEPATH
				fi
				done
			# fix root/.packages/woof-installed-packages
			grep -v "$PKG" $SFSROOT/root/.packages/woof-installed-packages| \
				while read LINE
					do 
					echo $LINE >> $SFSROOT/root/.packages/woof-installed-packages.tmp
					done
			mv -f $SFSROOT/root/.packages/woof-installed-packages.tmp \
				$SFSROOT/root/.packages/woof-installed-packages		 
			rm $D/$PKG
			if [ $? -ne 0 ]; then
				echo "Failed to move $PKG into extras.sfs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				echo "$PKG was moved " >> $CWD/build.log
			fi
			statusfunc $?
		fi
	done

	cd $SQDIR
	
	# Change default text editor
	if [ ! -f $SFSROOT/usr/bin/geany ] ; then
		if [ -f $SFSROOT/usr/bin/leafpad ] ; then
			sed -i 's/geany/leafpad/' $SFSROOT/usr/local/bin/defaulttexteditor
		else
			sed -i 's/geany/nicoedit/' $SFSROOT/usr/local/bin/defaulttexteditor
		fi
	fi
	
	# Change default browser
	if [ ! -f $SFSROOT/usr/bin/seamonkey ] && [ -f $SFSROOT/usr/bin/midori ] ; then
		sed -i 's/gtkmoz/midori/' $SFSROOT/usr/local/bin/defaulthtmlviewer
		sed -i 's/mozstart/midori/' $SFSROOT/usr/local/bin/defaultbrowser
		if [ ! -f $SFSROOT/usr/lib/libnotify.so.1 ] ; then
			cd $SFSROOT/usr/lib/
			ln -sf libnotify.so.[2-4] libnotify.so.1
			cd $SQDIR
		fi
	fi
	
else
	echo "Nothing moved out of the main sfs"
	echo "Nothing was moved into the extras.sfs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
fi

cd $SFSROOT

# Fix permissions for fido
chmod -R 777 tmp

#log list of XO-specific files included
echo "The following XO-specific files where included in the build" >> $CWD/build.log
#SAFE=$(printf "%s\n" "$XOSFS" | sed 's/[][\.*^$(){}?+|/]/\\&/g')
y=$(printf "%s\n" "$XOSFS" | sed 's/[/]/\\&/g') # specific case
find $XOSFS | sed s/$y//g >> $CWD/build.log

# Do not overwrite rtcwake if present. May overwrite busybox!
[ -f usr/sbin/rtcwake ] && rm -f $XOSFS/usr/sbin/rtcwake 
echo "copying in the XO files"
cp -aRf $XOSFS/* ./
cp -aRf $XOSFS/.[a-zA-Z0-9]* ./

statusfunc $?

# Add the build log in the sfs
BNAME=`echo "$ISO" | sed 's/\.iso//'`
gzip -c $CWD/build.log > $SFSROOT/usr/local/share/$BNAME-XO_build.log.gz
# compress main sfs
cd $SQDIR
sync
[ "$SERVPACK" != "" ] && cp $SFSROOT/etc/DISTRO_SPECS $CWD/ && MAINSFS="$DISTRO_PUPPYSFS" #service_pack in build
echo "now compressing the NEW $MAINSFS..."
mksquashfs squashfs-root/ "$MAINSFS"
sync
# add id string into the main sfs
echo -n "$DISTRO_IDSTRING" >> "$MAINSFS"
sync

statusfunc $?
echo "removing expanded filesystem"
rm -rf $SFSROOT 
sync
statusfunc $?

if [ -d $SQDIR/extras ] ; then
	cd $SQDIR
	echo "now compressing the \"extras.sfs\"..."
	mksquashfs extras extras.sfs
	sync
	statusfunc $?
	rm -rf extras
	sync
	statusfunc $?
fi

#============================== Mod initrd ===================================

# mod the initrd
cd $INITDIR
for DIR in XO*

#get xo hw version
 do VER="`echo $DIR|sed -e 's%^XO%%' -e 's%kernel$%%'`"
	case $VER in
	1)VERDIR=10
		XO=XO1 ;;
	1.5)VERDIR=15
		XO=XO1.5 ;;
	*)echo "not supported" && break && exit 0 ;;
	esac

[ -f boot${VERDIR}/initrd.* ] && rm -f boot${VERDIR}/initrd.*
echo "Making the ${XO} initrd.gz"
mkdir $CWD/initramfs
cd initramfs
# unpack initrd
gunzip -c ../initrd.gz | cpio -i 
statusfunc $?
sync
# Replace kernel modules with OLPC_Puppy ones
rm -rf lib/modules/*
cp -arf ../$DIR/lib/* lib/ 
[ "$SERVPACK" != "" ] && cp -f $CWD/DISTRO_SPECS . #service_pack in build
# The default puppy init looks for files only in the folder where vmlinuz is.
# it does not work with our boot10/15 setup 
sed -i "s/PSUBDIR=\"\`dirname \$ONEPUPFILE\`\"/PSUBDIR=\"\"/" init
# modprobe vfat if we are booting from  vfat formatted media
sed -i "s/vfat)/vfat) \\n   modprobe vfat/" init 
sync
# compress initrd
find . -print | cpio -H newc -o | gzip -9 > ../boot${VERDIR}/initrd.img
statusfunc $?
sync
# Cleanup
cd ..
rm -rf initramfs/*
echo "find kernel and initrd in the $DIR diectory"
done

cd $SQDIR
cd ..

#========================== Finish/cleanup/copy build ========================

# move everything to top level
[ ! -d build ] && mkdir build
echo "copying files into build"
cp -arf $INITDIR/boot* build
mv -f $INITDIR/initrd* build
mv -f $SQDIR/$MAINSFS build 
if [ -f $SQDIR/extras.sfs ] ; then
	mv -f $SQDIR/extras.sfs build
fi
rm -f build/initrd*
rm -f $INITDIR/boot*/initrd*

# Offer to add adrv if omitted
if [ "$ASFS" != "" ] && [ "$ADEL" = "d" ];then
		echo -e "\\0033[1;34m"
		echo  "The adrv of this puppy was excluded from the main SFS"
		echo  "Do you want to add it now in the XO build?"
		echo  "Hit \"a\" and enter to add it or just \"enter\" to ommit it"
		echo -en "\\0033[0;39m"
		read ADDADRV
		if [ "$ADDADRV" = "a" ];then
			[ ! -d  $CWD/mntiso ] && mkdir $CWD/mntiso
			echo "mounting $ISO"
			mount $ISOPATH $MNTDIR -o loop
			statusfunc $?
			cp $MNTDIR/adrv*.sfs build
			sync
			umount $MNTDIR
			rm -rf $MNTDIR
		else
			echo "ok"
		fi
fi

# Append IDSTRING to kernel. Needed when saving to the entire partition
for i in `ls build/boot*/vmlinuz`
	do
		echo -n "$DISTRO_IDSTRING" >> $i
	done
statusfunc $?
sync

# cleanup
echo "removing working dirs"
rm -rf $SQDIR
rm -rf initramfs
[ "$SERVPACK" != "" ] && rm -f $CWD/DISTRO_SPECS #service_pack in build

# workaround a strange race (?) issue with libertas and 3.3 kernel 
if [ "`ls $CWD/boot1* | grep '3.3'`" != "" ] ; then
	sed -i 's/\" expand\$ to boot-file/ loglevel=7\" expand\$ to boot-file/' build/boot/olpc.fth
fi

# option to install to a usb drive
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
			rm -rf $DEVICE/boot*
			cp -aR --remove-destination build/* $DEVICE/
			sync
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

unset DISTRO_FILE_PREFIX #just to make sure, maybe the whole lot? Nah not exported
xoolpcfunc
statusfunc 0 

echo -e "\\0033[1;34m"
echo " Done!"
echo -en "\\0033[0;39m"

