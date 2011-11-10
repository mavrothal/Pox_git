#!/bin/bash

# check if the build system has aufs
if [ ! -f /usr/include/linux/aufs_type.h ] ; then
	echo -e "\\0033[1;31m"
	echo "To build aufs-utilities you must be running an aufs-patched"
	echo "kernel and have kernel headers installed. Will not build aufs-util"
	echo -en "\\0033[0;39m"
	echo "Building Aufs utilities failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	sleep 5
	exit 1
fi

BASEDIR=`pwd`
CWD="$BASEDIR" 
if [ ! -d $BASEDIR/XO_SFS_sources ] ; then 
	mkdir $BASEDIR/XO_SFS_sources
fi
XO_sources="$BASEDIR/XO_SFS_sources"
if [ ! -d $BASEDIR/XO_sfs ] ; then 
	mkdir $BASEDIR/XO_sfs
fi
output="$BASEDIR/XO_sfs"

KMAJ=`uname -r | cut -f 1 -d '.'`

download3 ()
{
	if [ ! -d "$XO_sources/aufs-util" ] ; then
		cd $XO_sources
		git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs-util.git  2>&1
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to download the Aufs-utils."
			echo "Check the connection and try again"
			echo -en "\\0033[0;39m"
			exit 1
		fi
	else  
		cd $XO_sources/aufs-util
		git reset --hard HEAD
		git fetch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to update the Aufs-utils."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "with the old sources or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "Aufs-util git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi
	fi
}
export -f download3
	
download2 ()
{
	if [ ! -d "$XO_sources/aufs2-util" ] ; then
		cd $XO_sources
		git clone git://aufs.git.sourceforge.net/gitroot/aufs/aufs2-util.git  2>&1
		if [ $? -ne 0 ]; then
			git clone git://git.c3sl.ufpr.br/aufs/aufs2-util.git  2>&1
			if [ $? -ne 0 ]; then
				echo -e "\\0033[1;31m"
				echo "Error: failed to download the Aufs2-utils."
				echo "Check the connection and try again"
				echo -en "\\0033[0;39m"
				exit 1
			fi
		fi
	else  
		cd $XO_sources/aufs2-util
		git reset --hard HEAD
		git fetch
		if [ $? -ne 0 ]; then
			echo -e "\\0033[1;31m"
			echo "Error: failed to update the Aufs2-utils."
			echo -e "\\0033[1;34m"
			echo "Hit \"c\"  and then  \"enter\" to continue"
			echo "with the old sources or just \"enter\" to quit,"
			echo "check the connection and try latter."
			echo -en "\\0033[0;39m"
			read CONTINUE
			if [ "$CONTINUE" = "c" ];then
				echo "Aufs2-util git update failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
			else
				exit 0
			fi
		fi
	fi			
}
export -f download2	

bld_utils ()
{
	# Do not build statically
	sed -i 's/static/shared/' Makefile
	# Install in XO_sfs
	export output 
	sed -i 's/DESTDIR/output/g' Makefile
	sed -i 's/DESTDIR/output/g' libau/Makefile		
	make
	if [ $? -ne 0 ]; then 
		echo "Building Aufs utilities failed. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
		echo -e "\\0033[1;31m"
		echo "Building Aufs utilities failed"
		echo -en "\\0033[0;39m"
		sleep 5
	else 
		echo "Aufs utilities were build sucessfully. $(date "+%Y-%m-%d %H:%M")" >> $CWD/build.log
	fi
	make install
	make clean
}
export -f bld_utils

cd $XO_sources
	
# Sellect Aufs-util version to build
echo
echo -e "\\0033[1;34m"
echo "To build aufs_utils for the 3.x kernels hit \"3\""
echo "and then  \"enter\".  Just \"enter\" to build "
echo "aufs_utils for the 2.6.x kernel"
echo -en "\\0033[0;39m"
read CONTINUE
if [ "$CONTINUE" = "3" ] ; then
	if [ "$KMAJ" != "3" ] ; then
		echo
		echo -e "\\0033[1;31m"
		echo "Building aufs_utils for the 3.x kernels in a system"
		echo "running a 2.6.x kernel is likely to fail!"		 
		echo "hit \"c\" and then  \"enter\" to take your chances"
		echo "or just \"enter\" to exit "
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" = "c" ] ; then
			download3
			cd $XO_sources/aufs-util
			git checkout origin/aufs3.0
			bld_utils		
		else
			exit 0
		fi
	else
		download3
		cd $XO_sources/aufs-util
		git checkout origin/aufs3.0
		bld_utils
	fi				
else
	if [ "$KMAJ" != "2" ] ; then
		echo
		echo -e "\\0033[1;31m"
		echo "Building aufs_utils for the 2.6.x kernels in a system"
		echo "running a 3.x kernel is likely to fail!"		 
		echo "hit \"c\" and then  \"enter\" to take your chances"
		echo "or just \"enter\" to exit "
		echo -en "\\0033[0;39m"
		read CONTINUE
		if [ "$CONTINUE" = "c" ] ; then
			download2
			cd $XO_sources/aufs2-util
			git checkout origin/aufs2.2
			bld_utils
		else
			exit 0
		fi
	else
		download2
		cd $XO_sources/aufs2-util
		git checkout origin/aufs2.2
		bld_utils
	fi			
fi
