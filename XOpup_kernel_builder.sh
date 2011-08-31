#!/bin/bash
# 
# This script will build a kernel capable of running puppylinux
# on the OLPC XO-1 and XO-1.5 laptops.
# Use in combination with the create_xo_puppy script to make any
# flavor XOpup running an updated 2.6.35 OLPC kernel
#
# GPL2 (see /usr/share/doc) (c) mavrothal, 01micko
# NO WARRANTY

#ver
VER=7 

# fail-safe switch in case someone clicks the script in ROX 
#echo -e "\\0033[1;34m"
#read -p "Press ENTER to begin" dummy
#echo -en "\\0033[0;39m"

BASEDIR=`pwd`
CWD="$BASEDIR" 
mkdir $BASEDIR/kernel_sources
sources="$BASEDIR/kernel_sources"
git_clone="$sources/olpc-2.6"
git_clone_aufs="$sources/aufs2-standalone"
patches="$BASEDIR/XO_kernel_patches"

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
	This program will build Puppylinux-compatible kernels for the 
	OLPC XO-1 and XO-1.5 laptops
	
	-h|--help	display this usage
	-v|--version	display script version
	-d|--download 	only download the sources
	-1|--xo1 	download and build the XO-1 kernel
	-5|--xo15 	download and build the XO-1.5 kernel
	-b|--build 	download and build everything  
	
	NOTE: The program will download ~600 MB of data and requires
	at least 1 GB of free disk space. Make sure you have all the
	compiling tools for your Linux distribution 	
	
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
}
export -f check_dev	

check_space()
{
	#test for free space
	BASEDISK="`echo $CWD|cut -d '/' -f 1,2,3`" #returns eg "/mnt/sda1"
	BASEPART="`echo $CWD|cut -d '/' -f 3`" #returns eg "sda1" if not in pupsave
	if [ "$BASEPART" = "home" ] ; then
		DF="`df -m|grep dev_save|awk '{print $4}'`"
	else
		DF="`df -m|grep $BASEPART|awk '{print $4}'`"
	fi
	#puppy specific
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
	#cheat!
		if [ "`echo $BASEDISK|grep "root"`" != "" ];then 
		DF="`cat /tmp/pup_event_sizefreem`"
		fi
	fi
	if test "$DF" -lt "1000" ;then EXIT=1
		echo "space check... disk space free is $DF MB"
		echo "...not enough space, do this on another partiton"
			else EXIT=0
		echo "space check... disk space free is $DF MB"
	fi
}
export -f check_space

get_sources() 
{

	# Get needed files
	if [ ! -d "$git_clone" ] ; then
		cd $sources
		echo " Please be patient. It can take an hour..."
		git clone git://dev.laptop.org/olpc-2.6 2>&1
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the kernel sources."
			echo "Check the connection and try again"
			echo -en "\\0033[0;39m"
			exit 1
		fi
	else 
		cd $git_clone
		git reset --hard HEAD
		git fetch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to update the kernel sources."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "with the old sources or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "OLPC-2.6 git update failed" >> $CWD/build.log
			else
				exit 0
			fi
		fi
	fi
	sync

	if [ ! -d "$git_clone_aufs" ] ; then
		cd $sources
		git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs2-standalone.git 2>&1
		if [ $? -ne 0 ]; then
			git clone git://git.c3sl.ufpr.br/aufs/aufs2-standalone.git
			if [ $? -ne 0 ]; then
				echo -e "\\0033[1;31m"
				echo "Error: failed to download the Aufs sources."
				echo "Check the connection and try again"
				echo -en "\\0033[0;39m"
				exit 1
			fi
		fi
	else  
		cd $git_clone_aufs
		git reset --hard HEAD
		git fetch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to update the Aufs sources."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "with the old sources or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "Aufs git update failed" >> $CWD/build.log
			else
				exit 0
			fi
		fi	
	fi
	sync 
}
export -f get_sources

patch_sources() 
{
	output="$BASEDIR"
	
	# Point aufs git to kernel version 2.6.35
	cd $git_clone_aufs
	git checkout origin/aufs2.2-35
	if [ ! -d patches ] ; then 
		mkdir patches
		mv *.patch patches/
	fi
	

	# Patch the OLPC kernel
	cd $git_clone
	git checkout origin/olpc-2.6.35
	sync

	# Apply patches and aufs source in kernel
	cp -aR $git_clone_aufs/fs .
	cp -aR $git_clone_aufs/Documentation .
	cp -a $git_clone_aufs/include/linux/aufs_type.h include/linux/
	
	 
	for patch in $git_clone_aufs/patches/*; do
		echo "Applying $patch"
		patch -p1 < $patch
		if [ $? -ne 0 ]; then
			echo "Error: failed to apply $patch on the kernel sources."
			exit 1
		fi
	done

	# Apply puppy-specific and config patches
	for patch in $patches/*; do
		echo "Applying $patch"
		patch -p1 < $patch
		if [ $? -ne 0 ]; then
			echo "Error: failed to apply $patch on the kernel sources."
			exit 1
		fi
	done
	
	# Remove the "+" signed that is added at the end of the kernel extraversion
	sed -rie 's/echo "\+"/#echo "\+"/' scripts/setlocalversion

	sync
}
export -f patch_sources

make_XO1_kernel()
{
	# Make output dirs
	mkdir $output/XO1kernel
	mkdir $output/boot10
	
	# Check if a build is there
	if [ -f $output/boot10/vmlinuz ] ; then
		echo " An XO-1 kernel is alreday build! "
		echo " Please detete or move it and run again "
		echo -e "\\0033[1;34m"
		echo " Done! "
		echo -en "\\0033[0;39m"
		xoolpcfunc
		exit 0
	fi
	
	# Make XO-1 kernel
	echo -e "\\0033[1;34m"
	echo "Making XO-1 kernel"
	echo -en "\\0033[0;39m"
	kernsub=`cat Makefile |grep ^SUBLEVEL | cut -f2 -d "=" | tr -d ' '`
	kernextr=`cat Makefile |grep ^EXTRAVERSION | cut -f2 -d "=" | tr -d ' ' | cut -f1 -d "_"`
	gitcommit=`cat .git/HEAD | awk '{print substr($0,1,7)}'`
	kernel_ver="2.6."$kernsub""$kernextr"_xo1-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_Puppy"
	# Change kernel extra version
	sed -i "s/^EXTRAVERSION = [.a-zA-Z0-9_-]*/EXTRAVERSION = "$kernextr"_xo1-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_Puppy/" Makefile
	make clean distclean
	make mrproper
	sync
	cp arch/x86/configs/xo_1_defconfig .config
	make headers_check
	make INSTALL_HDR_PATH=$output/XO1kernel/kernel-headers-$kernel_ver headers_install
	find $output/XO1kernel/kernel-headers-$kernel_ver/include \( -name .install -o -name ..install.cmd \) -delete
	make bzImage modules
	cp .config $output/boot10/config-$kernel_ver
	cp arch/x86/boot/bzImage $output/boot10/vmlinuz
	make INSTALL_MOD_PATH=$output/XO1kernel/ modules_install
	rm -rf $output/XO1kernel/lib/firmware
	# Fix the modules.dep since without full path do not work in puppy's initrd
	sed -i "s/kernel\//\/lib\/modules\/"$kernel_ver"\/kernel\//g" $output/XO1kernel/lib/modules/$kernel_ver/modules.dep
	make clean distclean
	sync
	package_source
	echo "XO-1 kernel build finished" >> $CWD/build.log	
}
export -f make_XO1_kernel

make_XO15_kernel()
{
	# Make output dirs
	mkdir $output/XO1.5kernel
	mkdir $output/boot15
	
	# Check if a build is there
	if [ -f $output/boot15/vmlinuz ] ; then
		echo " An XO-1.5 kernel is alreday build! "
		echo " Please detete or move it and run again "
		echo -e "\\0033[1;34m"
		echo " Done! "
		echo -en "\\0033[0;39m"
		xoolpcfunc
		exit 0
	fi
	
	# Make XO-1.5 kernel
	echo -e "\\0033[1;34m"
	echo "Making XO-1.5 kernel"
	echo -en "\\0033[0;39m"
	kernsub=`cat Makefile |grep ^SUBLEVEL | cut -f2 -d "=" | tr -d ' '`
	kernextr=`cat Makefile |grep ^EXTRAVERSION | cut -f2 -d "=" | tr -d ' ' | cut -f1 -d "_"`
	gitcommit=`cat .git/HEAD | awk '{print substr($0,1,7)}'`
	kernel_ver="2.6."$kernsub""$kernextr"_xo1.5-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_Puppy"
	# Change kernel extra version
	sed -i "s/^EXTRAVERSION = [.a-zA-Z0-9_-]*/EXTRAVERSION = "$kernextr"_xo1.5-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_Puppy/" Makefile
	make clean distclean
	make mrproper
	sync
	cp arch/x86/configs/xo_1.5_defconfig .config
	make headers_check
	make INSTALL_HDR_PATH=$output/XO1.5kernel/kernel-headers-$kernel_ver headers_install
	find $output/XO1.5kernel/kernel-headers-$kernel_ver/include \( -name .install -o -name ..install.cmd \) -delete
	make bzImage modules
	cp .config $output/boot15/config-$kernel_ver
	cp arch/x86/boot/bzImage $output/boot15/vmlinuz
	make INSTALL_MOD_PATH=$output/XO1.5kernel/ modules_install
	rm -rf $output/XO1.5kernel/lib/firmware
	# Fix the modules.dep since without full path do not work in puppy's initrd
	sed -i "s/kernel\//\/lib\/modules\/"$kernel_ver"\/kernel\//g" $output/XO1.5kernel/lib/modules/$kernel_ver/modules.dep
	make clean distclean
	sync
	package_source
	echo "XO-1.5 kernel build finished" >> $CWD/build.log			
}
export -f make_XO15_kernel

package_source()
{
	echo -e "\\0033[1;34m"
	echo "Packing the kernel source. May take a little... "
	echo -en "\\0033[0;39m"
	rm -rf $output/usr
	sync
	mkdir -p $output/usr/src/linux
	mkdir $output/build_kernels_source
	tar -X */.gitignore -X */*/.gitignore  -X */*/*/.gitignore \
	-X */*/*/*/.gitignore -X */*/*/*/*/.gitignore olpc/.tarignore \
	--exclude=.git -cf - . | tar -xf - -C $output/usr/src/linux
	sync
	cd $output 
	tar cjf build_kernels_source/$kernel_ver.src.tar.bz2 usr/
	sync
	rm -rf usr
	cd $git_clone
}
export -f package_source

finished()
{
	if [ -f $output/$kernel_ver.src.tar.bz2 ] ; then
		cd $git_clone_aufs
		git reset --hard HEAD 
		cd $git_clone
		git reset --hard HEAD
		echo -e "\\0033[1;34m"
		echo " Done! "
		echo "Find kernels in the "$output" folder"
		echo -en "\\0033[0;39m"
		xoolpcfunc
		cd $CWD
		exit 0
	else
		echo -e "\\0033[1;34m"
		echo " Done! "
		echo -en "\\0033[0;39m"
		xoolpcfunc
		cd $CWD
		exit 0
	fi
}
export -f finished

case $1 in 
-h|--help) usagefunc && exit 0 ;;
-v|--version) echo "$VER" && exit 0 ;;
-xh|--extended-help) echo "Coming soon..." 
					xoolpcfunc && exit 0 ;;
-d|--download) check_space && get_sources && finished ;;
-1|--xo1)check_dev && check_space && get_sources
		patch_sources && make_XO1_kernel && finished ;;
-5|--xo15)check_dev && check_space && get_sources
		patch_sources && make_XO15_kernel && finished ;;
-b|--build)check_dev && check_space && get_sources
		patch_sources && make_XO1_kernel
		make_XO15_kernel && finished ;;
esac
