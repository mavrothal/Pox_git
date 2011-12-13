#!/bin/bash
# 
# This script will build a kernel capable of running puppylinux
# on the OLPC XO-1 and XO-1.5 laptops.
# Use in combination with the create_xo_puppy script to make any
# flavor XOpup running an updated 2.6.35 OLPC kernel or the new
# (and for now experimental) OLPC 3.1.0 kernel
#
# GPL2 (see /usr/share/doc) (c) mavrothal, 01micko
# NO WARRANTY

#ver
VER=13 

# fail-safe switch in case someone clicks the script in ROX 
#echo -e "\\0033[1;34m"
#read -p "Press ENTER to begin" dummy
#echo -en "\\0033[0;39m"

BASEDIR=`pwd`
CWD="$BASEDIR" 
mkdir $BASEDIR/kernel_sources
sources="$BASEDIR/kernel_sources"
git_clone="$sources/olpc-2.6"
git_clone_aufs2="$sources/aufs2-standalone"
git_clone_aufs3="$sources/aufs3-standalone"
union_patch="$sources/unionfs-2.5.10_for_3.1.*.diff"
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
			echo "OLPC-2.6 kernel source dowanload failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			exit 1
		fi
	else 
		cd $git_clone
		git reset --hard HEAD
		git clean -fdx
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
				echo "OLPC-2.6 git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi
	fi
	sync

	if [ ! -d "$git_clone_aufs2" ] ; then
		cd $sources
		git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs2-standalone.git 2>&1
		if [ $? -ne 0 ]; then
			git clone git://git.c3sl.ufpr.br/aufs/aufs2-standalone.git
			if [ $? -ne 0 ]; then
				echo -e "\\0033[1;31m"
				echo "Error: failed to download the Aufs sources."
				echo "Check the connection and try again"
				echo -en "\\0033[0;39m"
				echo "Aufs source dowanload failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				exit 1
			fi
		fi
	else  
		cd $git_clone_aufs2
		git reset --hard HEAD
		git clean -fdx
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
				echo "Aufs git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi	
	fi
	sync 
	
	if [ ! -d "$git_clone_aufs3" ] ; then
		cd $sources
		git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs3-standalone.git 2>&1
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the Aufs sources."
			echo "Check the connection and try again"
			echo -en "\\0033[0;39m"
			echo "Aufs source dowanload failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			exit 1
		fi
	else  
		cd $git_clone_aufs3
		git reset --hard HEAD
		git clean -fdx
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
				echo "Aufs git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi	
	fi
	sync 
	
	if [ ! -f $union_patch ] ; then
		cd $sources
		wget -c ftp://ftp.filesystems.org/pub/unionfs/unionfs-2.x-latest/unionfs-2.5.10_for_3.1.*.diff.gz
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the unionfs patch."
			echo "Check the connection and try again"
			echo -en "\\0033[0;39m"
			echo "Unionfs source dowanload failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			exit 1
		fi
		sync
		gzip -d unionfs-2.5.10_for_3.1.*.diff.gz		
	else
		echo -e "\\0033[1;34m"
		echo "A unionfs patch already exits."
		echo "Hit \"c\"  and then  \"enter\" to delete and re-download"
		echo "or just \"enter\" to use the old one"
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" = "c" ];then
			cd $sources
			rm -f $union_patch*
			wget -c ftp://ftp.filesystems.org/pub/unionfs/unionfs-2.x-latest/unionfs-2.5.10_for_3.1.*.diff.gz
			if [ $? -ne 0 ]; then
				echo -e "\\0033[1;31m"
				echo "Error: failed to download the unionfs patch."
				echo "Check the connection and try again"
				echo -en "\\0033[0;39m"
				echo "Unionfs source dowanload failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				exit 1
			fi
			sync
			gzip -d unionfs-2.5.10_for_3.1.*.diff.gz			
		else
			echo "Using preexisting Unionfs patch. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		fi
	fi
}
export -f get_sources

patch_sources() 
{
	output="$BASEDIR"
	
	# Sellect kernel to build
	echo
	echo -e "\\0033[1;34m"
	echo "To build the experimental 3.1 kernel"
	echo "hit \"3\"  and then  \"enter\" "
	echo "or just \"enter\" to build the 2.6.35 kernel"
	echo -en "\\0033[0;39m"
	read CONTINUE
	if [ "$CONTINUE" = "3" ];then
		echo
		echo -e "\\0033[1;34m"
		echo "To build the 3.1 kernel with Unionfs "
		echo "hit \"u\"  and then  \"enter\" "
		echo "or just \"enter\" to build with Aufs"
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" != "u" ];then	
			# Point aufs git to kernel version 3.1
			cd $git_clone_aufs3
			git checkout origin/aufs3.1
			if [ ! -d patches ] ; then 
				mkdir patches
				mv *.patch patches/
			else
				mv *.patch patches/
			fi	

			# Patch the OLPC kernel
			cd $git_clone
			git checkout origin/x86-3.1
			sync

			# Apply patches and aufs source in kernel
			cp -aR $git_clone_aufs3/fs .
			cp -aR $git_clone_aufs3/Documentation .
			cp -a $git_clone_aufs3/include/linux/aufs_type.h include/linux/
		 
			for patch in $git_clone_aufs3/patches/*; do
				echo "Applying $patch"
				patch -p1 < $patch
				if [ $? -ne 0 ]; then
					echo -e "\\0033[1;31m"
					echo "Error: failed to apply $patch on the kernel sources."
					echo -en "\\0033[0;39m"
					echo "Failed to apply $patch on the kernel sources. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
					exit 1
				else
					echo "Building kernel 3.x with Aufs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
					LAYERFS="Aufs"
				fi
			done

			# Apply config patches
			for patch in $patches/3.1/*; do
				echo "Applying $patch"
				patch -p1 < $patch
				if [ $? -ne 0 ]; then
					echo -e "\\0033[1;31m"
					echo "Error: failed to apply $patch on the kernel sources."
					echo -en "\\0033[0;39m"
					echo "Failed to apply $patch on the kernel sources. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
					exit 1
				fi
			done
		else
			# Patch the OLPC kernel with unionfs
			cd $git_clone
			git checkout origin/x86-3.1
			sync
			NUMBER=`ls -l $union_patch | wc -l | tr -d ' '`
			if [ "$NUMBER" != "1" ] ; then 
				echo -e "\\0033[1;31m"
				echo "There are more than one unionfs patches in $sources "
				echo "Please delete or move the ones you do not need and try again"
				echo -en "\\0033[0;39m"
				echo "Too many Unionfs patches. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				exit 1
			fi
			patch -RNp1 < $union_patch 
			if [ $? -ne 0 ]; then
				patch -Np1 < $union_patch
				if [ $? -ne 0 ]; then
					echo -e "\\0033[1;31m"
					echo "Error: failed to apply Unionfs patch on the kernel sources."
					echo -en "\\0033[0;39m"
					echo "Failed to apply Unionfs patch on the kernel sources. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
					exit 1
				else
					echo "Building kernel 3.x with Unionfs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
					LAYERFS="Unionfs"
				fi
			fi
			
			# Apply config patches
			for patch in $patches/3.1_union/*; do
				echo "Applying $patch"
				patch -p1 < $patch
				if [ $? -ne 0 ]; then
					echo -e "\\0033[1;31m"
					echo "Error: failed to apply $patch on the kernel sources."
					echo -en "\\0033[0;39m"
					echo "Failed to apply $patch on the kernel sources. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
					exit 1
				fi
			done
		fi
	else	
		# Point aufs git to kernel version 2.6.35
		cd $git_clone_aufs2
		git checkout origin/aufs2.2-35
		if [ ! -d patches ] ; then 
			mkdir patches
			mv *.patch patches/
		else
			mv *.patch patches/
		fi
	
		# Patch the OLPC kernel
		cd $git_clone
		git checkout origin/olpc-2.6.35
		sync

		# Apply patches and aufs source in kernel
		cp -aR $git_clone_aufs2/fs .
		cp -aR $git_clone_aufs2/Documentation .
		cp -a $git_clone_aufs2/include/linux/aufs_type.h include/linux/
	 
		for patch in $git_clone_aufs2/patches/*; do
			echo "Applying $patch"
			patch -p1 < $patch
			if [ $? -ne 0 ]; then
				echo -e "\\0033[1;31m"
				echo "Error: failed to apply $patch on the kernel sources."
				echo -en "\\0033[0;39m"
				echo "Failed to apply $patch on the kernel sources. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				exit 1
			else
				echo "Building kernel 2.6.x with Aufs. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				LAYERFS="Aufs"
			fi
		done

		# Apply config patches
		for patch in $patches/2.6/*; do
			echo "Applying $patch"
			patch -p1 < $patch
			if [ $? -ne 0 ]; then
				echo -e "\\0033[1;31m"
				echo "Error: failed to apply $patch on the kernel sources."
				echo -en "\\0033[0;39m"
				echo "Failed to apply $patch on the kernel sources. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
				exit 1
			fi
		done
	fi
	
	# Apply puppy patches
	for patch in $patches/puppy/*; do
		echo "Applying $patch"
		patch -p1 < $patch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to apply $patch on the kernel sources."
			echo -en "\\0033[0;39m"
			echo "Failed to apply $patch on the kernel sources. Kernel build aborted $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
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
	output_k=$output/XO1kernel
	mkdir $output/boot10
	
	# Check if a build is there
	if [ -f $output/boot10/vmlinuz ] ; then
		echo -e "\\0033[1;31m"
		echo " An XO-1 kernel is alreday build! "
		echo " Please detete or move it and run again "		
		echo -en "\\0033[0;39m"
		xoolpcfunc
		exit 0
	fi
	
	# Make XO-1 kernel
	echo -e "\\0033[1;34m"
	echo "Making XO-1 kernel"
	echo -en "\\0033[0;39m"
	KVER=`cat Makefile |grep ^VERSION | cut -f2 -d "=" | tr -d ' '`
	KPATCH=`cat Makefile |grep ^PATCHLEVEL | cut -f2 -d "=" | tr -d ' '`
	KSUB=`cat Makefile |grep ^SUBLEVEL | cut -f2 -d "=" | tr -d ' '`
	kernextr=`cat Makefile |grep ^EXTRAVERSION | cut -f2 -d "=" | tr -d ' ' | cut -f1 -d "_"`
	gitcommit=`cat .git/HEAD | awk '{print substr($0,1,7)}'`
	kernel_ver=""$KVER"."$KPATCH"."$KSUB""$kernextr"_xo1-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_"$LAYERFS""
	# Change kernel extra version
	NOkernextr=`cat Makefile |grep ^EXTRAVERSION | cut -f2 -d "="`
	if [ "$NOkernextr" = "" ] ; then  
		sed -i "s/^EXTRAVERSION =/EXTRAVERSION = "$kernextr"_xo1-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_"$LAYERFS"/" Makefile
	else
		sed -i "s/^EXTRAVERSION = [.a-zA-Z0-9_-]*/EXTRAVERSION = "$kernextr"_xo1-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_"$LAYERFS"/" Makefile
	fi
	make clean distclean
	make mrproper
	sync
	cp arch/x86/configs/xo_1_defconfig .config
	make headers_check
	mkdir -p $output_k/kernel-headers-$kernel_ver/usr 
	make INSTALL_HDR_PATH=$output_k/kernel-headers-$kernel_ver/usr headers_install
	find $output_k/kernel-headers-$kernel_ver/usr/include \( -name .install -o -name ..install.cmd \) -delete
	make bzImage modules
	cp .config $output/boot10/config-$kernel_ver
	cp arch/x86/boot/bzImage $output/boot10/vmlinuz
	make INSTALL_MOD_PATH=$output_k/ modules_install
	# Pack kernel firmware with kernel headers
	mkdir -p $output_k/kernel-headers-$kernel_ver/lib
	mv $output_k/lib/firmware $output_k/kernel-headers-$kernel_ver/lib/
	# Fix the modules.dep since without full path do not work in puppy's initrd
	sed -i "s/kernel\//\/lib\/modules\/"$kernel_ver"\/kernel\//g" $output_k/lib/modules/$kernel_ver/modules.dep
	# Fix symlinks
	rm $output_k/lib/modules/$kernel_ver/build
	rm $output_k/lib/modules/$kernel_ver/source 
	ln -sf /usr/src/linux  $output_k/lib/modules/$kernel_ver/build
	ln -sf /usr/src/linux  $output_k/lib/modules/$kernel_ver/source
	make clean distclean
	sync
	package_source
	cd $output_k/
	dir_2_pet kernel-headers-$kernel_ver/
	cd $git_clone
	echo "XO-1 kernel build finished. $(date "+%Y-%m-%d %H:%M") " >> $CWD/build.log	
}
export -f make_XO1_kernel

make_XO15_kernel()
{
	# Make output dirs
	mkdir $output/XO1.5kernel
	output_k=$output/XO1.5kernel
	mkdir $output/boot15
	
	# Check if a build is there
	if [ -f $output/boot15/vmlinuz ] ; then
		echo "\\0033[1;31m"
		echo " An XO-1.5 kernel is alreday build! "
		echo " Please detete or move it and run again "
		echo -en "\\0033[0;39m"
		xoolpcfunc
		exit 0
	fi
	
	# Make XO-1.5 kernel
	echo -e "\\0033[1;34m"
	echo "Making XO-1.5 kernel"
	echo -en "\\0033[0;39m"
	KVER=`cat Makefile |grep ^VERSION | cut -f2 -d "=" | tr -d ' '`
	KPATCH=`cat Makefile |grep ^PATCHLEVEL | cut -f2 -d "=" | tr -d ' '`
	KSUB=`cat Makefile |grep ^SUBLEVEL | cut -f2 -d "=" | tr -d ' '`
	kernextr=`cat Makefile |grep ^EXTRAVERSION | cut -f2 -d "=" | tr -d ' ' | cut -f1 -d "_"`
	gitcommit=`cat .git/HEAD | awk '{print substr($0,1,7)}'`
	kernel_ver=""$KVER"."$KPATCH"."$KSUB""$kernextr"_xo1.5-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_"$LAYERFS""
	# Change kernel extra version
	NOkernextr=`cat Makefile |grep ^EXTRAVERSION | cut -f2 -d "="`
	if [ "$NOkernextr" = "" ] ; then  
		sed -i "s/^EXTRAVERSION =/EXTRAVERSION = "$kernextr"_xo1.5-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_"$LAYERFS"/" Makefile
	else
		sed -i "s/^EXTRAVERSION = [.a-zA-Z0-9_-]*/EXTRAVERSION = "$kernextr"_xo1.5-"$(date "+%Y%m%d.%H%M")".olpc."$gitcommit"_"$LAYERFS"/" Makefile
	fi
	make clean distclean
	make mrproper
	sync
	cp arch/x86/configs/xo_1.5_defconfig .config
	make headers_check
	mkdir -p $output_k/kernel-headers-$kernel_ver/usr
	make INSTALL_HDR_PATH=$output_k/kernel-headers-$kernel_ver/usr headers_install
	find $output_k/kernel-headers-$kernel_ver/usr/include \( -name .install -o -name ..install.cmd \) -delete
	make bzImage modules
	cp .config $output/boot15/config-$kernel_ver
	cp arch/x86/boot/bzImage $output/boot15/vmlinuz
	make INSTALL_MOD_PATH=$output_k/ modules_install
	# Pack kernel firmware with kernel headers
	mkdir -p $output_k/kernel-headers-$kernel_ver/lib
	mv $output_k/lib/firmware $output_k/kernel-headers-$kernel_ver/lib/
	# Fix the modules.dep since without full path do not work in puppy's initrd
	sed -i "s/kernel\//\/lib\/modules\/"$kernel_ver"\/kernel\//g" $output_k/lib/modules/$kernel_ver/modules.dep
	# Fix symlinks
	rm $output_k/lib/modules/$kernel_ver/build
	rm $output_k/lib/modules/$kernel_ver/source 
	ln -sf /usr/src/linux  $output_k/lib/modules/$kernel_ver/build
	ln -sf /usr/src/linux  $output_k/lib/modules/$kernel_ver/source
	make clean distclean
	sync
	package_source
	cd $output_k/
	dir_2_pet kernel-headers-$kernel_ver/
	cd $git_clone
	echo "XO-1.5 kernel build finished. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log			
}
export -f make_XO15_kernel

package_source()
{
	echo -e "\\0033[1;34m"
	echo "Packing the kernel source. May take a little... "
	echo -en "\\0033[0;39m"
	rm -rf $output/"$kernel_ver".source
	sync
	mkdir -p $output/"$kernel_ver".source/usr/src/linux
	tar -X */.gitignore -X */*/.gitignore  -X */*/*/.gitignore \
	-X */*/*/*/.gitignore -X */*/*/*/*/.gitignore olpc/.tarignore \
	--exclude=.git -cf - . | tar -xf - -C $output/"$kernel_ver".source/usr/src/linux
	sync
	cd $output 
	mksquashfs "$kernel_ver".source/ $output_k/$kernel_ver.source.sfs
	sync
	rm -rf "$kernel_ver".source
}
export -f package_source

dir_2_pet()
{
	#Barry Kauler's dir2pet modified to work in XOpup_kernel_builder.sh mavrothal

	ADIR=$1
	MYPID=${$}

	#split ADIR path/filename into components...
	BASEPKG="`basename $ADIR`"
	DIRPKG="`dirname $ADIR`"
	[ "$DIRPKG" = "/" ] && DIRPKG=""

	NAMEONLY="kernel-headers-$kernel_ver"
	PUPMENUDESCR="kernel-headers for the $kernel_ver kernel"
	PUPCATEGORY="BuildingBlock"

	rm -f $DIRPKG/${BASEPKG}.tar 2>/dev/null
	rm -f $DIRPKG/${BASEPKG}.tar.gz 2>/dev/null
	rm -f $DIRPKG/${BASEPKG}.pet 2>/dev/null

	SIZEK="`du -s -k $DIRPKG/$BASEPKG | cut -f 1`" #w476

	echo ""$NAMEONLY"|"$NAMEONLY"|||"$PUPCATEGORY"|"$SIZEK"||"$NAMEONLY".pet||"$PUPMENUDESCR"||||" > $DIRPKG/$BASEPKG/pet.specs

	# Add pinstall.sh
	echo '#!/bin/sh' > $DIRPKG/$BASEPKG/pinstall.sh
	echo "if [ "\`uname -r\`" != "$kernel_ver" ] ; then" >> $DIRPKG/$BASEPKG/pinstall.sh
	echo "gtkdialog-splash -fontsize large -bg hotpink -icon gtk-dialog-error -close box -timeout 10 -text \"This is the WRONG pet for your running kernel! Please unistall this pet now\" &" >> $DIRPKG/$BASEPKG/pinstall.sh
	echo "fi" >> $DIRPKG/$BASEPKG/pinstall.sh
	chmod 755 $DIRPKG/$BASEPKG/pinstall.sh

	echo
	echo -e "\\0033[1;34m"
	echo "Packageing kernel headers in a pet..."
	echo -en "\\0033[0;39m"
	tar -c -f $DIRPKG/${BASEPKG}.tar $DIRPKG/$BASEPKG/
	sync
	gzip $DIRPKG/${BASEPKG}.tar
	TARBALL="$DIRPKG/${BASEPKG}.tar.gz"

	FULLSIZE="`stat --format=%s ${TARBALL}`"
	MD5SUM="`md5sum $TARBALL | cut -f 1 -d ' '`"
	echo -n "$MD5SUM" >> $TARBALL
	sync
	mv -f $TARBALL $DIRPKG/${BASEPKG}.pet
	rm -rf kernel-headers-$kernel_ver
	sync
}
export -f dir_2_pet

finished()
{
	if [ -f $output_k/kernel-headers-$kernel_ver.pet ] ; then
		cd $git_clone_aufs2
		git reset --hard HEAD
		cd $git_clone_aufs3
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
