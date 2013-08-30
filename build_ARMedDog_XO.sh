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
VER=0.1

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
#. $CWD/pkgs_remrc

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
		done
		for p in $(ls *.tbz)
		do 
			PNAME=`echo $p | sed 's/\.tbz//'`
			mkdir $PNAME
			tar xf $p -C $PNAME 2>/dev/null 
			cd $PNAME
			rm -rf install 2>/dev/null
			cp -aR * $SFSROOT
			if [ $? -ne 0 ]; then
				echo "Failed to add $p in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				echo "$p was added in the build. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			fi
			cd $extra_packs
			rm -rf $PNAME
		done
	fi		
}
export -f extra_packages

mod_fd-arm ()
{
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
	sed -i 's/localtime/utc/' $SFSROOT/etc/rc.d/rc.sysinit
	sed -i 's/hctosys/systohc/' $SFSROOT/etc/rc.d/rc.sysinit
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
	sed -i 's/\<size\>10/\<size\>12/g' $SFSROOT/etc/xdg/openbox/rc.xml
	sed -i 's/\<size\>8/\<size\>11/g' $SFSROOT/etc/xdg/openbox/rc.xml
	sed -i 's/X\=64/X\=128/g' $SFSROOT/etc/eventmanager
	#Default to net-setup if present
	if [ "$(ls $extra_packs/net_setup*)" != "" ]; then
		cat << EOF > $SFSROOT/usr/local/bin/defaultconnect
#!/bin/sh
exec net-setup.sh
EOF
	    chmof 755 $SFSROOT/usr/local/bin/defaultconnect
	fi
}
export -f mod_fd-arm
 
mod_XO_sfs ()
{
	rm -rf $XOSFS/.xo-nand
	rm -rf $XOSFS/etc/{modprobe.d,X11}
	rm -rf $XOSFS/usr/local
	rm -f $XOSFS/root/Startup/{0check_ker_ver,freeramdaemon.sh,powerapplet_xo,powerapplet3_xo}
	rm -f $XOSFS/root/{.freeramdaemon.rc,.guvcviewrc}
	#Start power managenet
	cat << EOF > $XOSFS/etc/rc.d/rc.local
#!/bin/ash

# Make sure that needed devices are added
udevadm trigger  --action=add --subsystem-match="input" --subsystem-match="sound" \\
--subsystem-match="usb" --subsystem-match="sdio" --subsystem-match="net" \\
--subsystem-match="mmc" --subsystem-match="rtc"
udevadm settle

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
	cd $CWD/initrdfs
	unsquashfs -d kernel-modules kernel-modules.sfs
	rm -rf kernel-modules/lib/modules/*
	if [ -d $CWD/XO175kernel/lib/modules/ ]; then
		cp -aR $CWD/XO175kernel/lib/modules/* kernel-modules/lib/modules/
		echo "Added XO-1.75 kernel modules in initrd" >> $CWD/build.log
		if [ -d $CWD/175aufs_utils ]; then
		    cp -a --remove-destination $CWD/175aufs_utils/* kernel-modules/
		    echo "Added XO-1.75 aufs_utils in initrd" >> $CWD/build.log
		fi
		sync
		rm -f kernel-modules.sfs
		mksquashfs kernel-modules/ kernel-modules.sfs
		cp -aR kernel-modules/* .
		rm -rf kernel-modules
		sync
		find . -print | cpio -H newc -o | gzip -9 > $CWD/build/boot/initrd.arm.2
		echo "Modified the XO-1.75 initrd" >> $CWD/build.log
	fi
	if [ -d $CWD/XO4kernel/lib/modules/ ]; then 
		rm -rf lib/modules/*
		unsquashfs -d kernel-modules kernel-modules.sfs
		rm -rf kernel-modules/lib/modules/*
		cp -aR $CWD/XO4kernel/lib/modules/* kernel-modules/lib/modules/
		echo "Added XO-4 kernel modules in initrd" >> $CWD/build.log
		if [ -d $CWD/175aufs_utils -a ! -d $CWD/40aufs_utils ]; then
			echo -e "\\0033[1;34m"
			echo  "Please build also aufs_utils for the XO-4 kernel"
			echo  "and then run the script again. Aborting."
			echo -en "\\0033[0;39m"
			exit 1
		else
		    cp -a --remove-destination $CWD/40aufs_utils/* kernel-modules/
		    echo "Added XO-4 aufs_utils in initrd" >> $CWD/build.log
		fi
		sync
		rm -f kernel-modules.sfs
		mksquashfs kernel-modules/ kernel-modules.sfs
		cp -aR kernel-modules/* .
		rm -rf kernel-modules
		sync
		find . -print | cpio -H newc -o | gzip -9 > $CWD/build/boot/initrd.arm.4
		echo "Modified the XO-4 initrd" >> $CWD/build.log
	fi
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
	dd if=uInitrd of=initrd.img bs=64 skip=1
	mkdir -p initrdfs
	cd initrdfs
	cat ../initrd.img | cpio -i
	cd $CWD
	rm -f uInitrd initrd.img
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
		extract_main_sfs && mod_sfs
		extract_initrd && mod_initrd 
		add_kernels && copy_to_device ;;
esac
