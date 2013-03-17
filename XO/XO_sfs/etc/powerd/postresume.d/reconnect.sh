#!/bin/sh

### This is a (modified) part of puppy's rc.sysinit

# First test if eth0 is up so if we do agressive suspend will not try to reconnect all the time
TestEth=`ifconfig | grep wlan`
if [  "$TestEth"  != "" ] && [  "`iwgetid -a`"  != "" ] ; then
   exit 0
fi

CHKFRISBEE=`cat /usr/local/bin/defaultconnect | grep -i Frisbee`
if [ "$CHKFRISBEE" != "" ] ; then
	if [ -f /usr/local/bin/Frisbee ] ; then
		sleep 5
		killall -9 dhcpcd
		killall wpa_cli
		/usr/local/Frisbee/start-dhcp
		killall -9 wpa_supplicant
		rm -rf /var/run/wpa_supplicant/*
		rm /tmp/wpa_supplicant.log
		/usr/local/Frisbee/start-wpa
		/usr/local/Frisbee/connect
	fi
	if [ -f /usr/local/bin/frisbee ] ; then
		INTERFACE=`cat /etc/frisbee/interface 2>/dev/null`
		dhcpcd -k
		killall -9 dhcpcd
		killall wpa_cli 2>/dev/null
		setsid dhcpcd -b -d $(dhcpcd_dropwait_option) -f /etc/frisbee/dhcpcd.conf
		sleep 2
		killall -9 wpa_supplicant 2>/dev/null
		rm -rf /var/run/wpa_supplicant/*
		rm -f /tmp/wpa_supplicant.log
		ifconfig $INTERFACE up
		if [ -f /etc/frisbee/.wpa_log_mode ] ; then
			setsid wpa_supplicant -B -d -Dwext -i$INTERFACE -c/etc/frisbee/wpa_supplicant.conf > /tmp/wpa_supplicant.log
		else
			setsid wpa_supplicant -B -Dwext -i$INTERFACE -c/etc/frisbee/wpa_supplicant.conf > /tmp/wpa_supplicant.log
		fi
	fi
else
###################FROM SETUP SERVICES################

if [ -h /dev/modem ];then
 DEVM="`readlink /dev/modem`"
 case $DEVM in
  modem) #error, circular link.
   rm -f /dev/modem
   DEVM=""
  ;;
  /dev/*) #wrong format.
   DEVM="`echo -n "$DEVM" | cut -f 3,4 -d '/'`"
   ln -snf $DEVM /dev/modem
  ;;
 esac
 case $DEVM in
  ttyS[0-9]) #apparently setserial can crash with other modems.
   setserial -v -b /dev/modem auto_irq skip_test autoconfig
  ;;
 esac
fi

#100227 choose default network tool...
NETCHOICE='other' #100304
DEFAULTCONNECT="`cat /usr/local/bin/defaultconnect | tail -n 1 | tr -s " " | cut -f 2 -d " "`"
[ "`grep 'gprs' /usr/local/bin/defaultconnect`" != "" ] && DEFAULTCONNECT='pgprs-connect'
[ "$DEFAULTCONNECT" = "gkdial" ] && DEFAULTCONNECT="pupdial" #for older pups.
case $DEFAULTCONNECT in
 Pwireless2)
  NETCHOICE='Pwireless2'
 ;;
 net-setup.sh)
  NETCHOICE='net-setup.sh'
 ;;
 net_wiz_classic)
  NETCHOICE='net_wiz_classic'
 ;;
 sns)
  NETCHOICE='sns'
 ;;
 *) #try determine which tool was used to setup networking...
  if [ -s /etc/simple_network_setup/connections ];then #100306
   NETCHOICE='sns'
  else
   CHECKOLDWIZ="`ls -1 /etc/*[0-9]mode 2>/dev/null`" #ex: eth0mode, wlan0mode.
   if [ "$CHECKOLDWIZ" != "" -a -d /usr/local/net_setup ];then
    NETCHOICE='net_wiz_classic'
   else
    CHECKNEWWIZ="`ls -1 /etc/network-wizard/network/interfaces 2>/dev/null`"
    if [ "$CHECKNEWWIZ" != "" ];then
     NETCHOICE='net-setup.sh'
    else
     [ -f /usr/local/Pwireless2/interface ] && NETCHOICE='Pwireless2' #100304
    fi
   fi
  fi
 ;;
esac
[ -f /etc/init.d/Pwireless2 ] && chmod 644 /etc/init.d/Pwireless2 #prevent jemimah's script from running. 100304 100513
case $NETCHOICE in
 Pwireless2)
  #this only sets up interface 'lo'...
  /etc/rc.d/rc.network_basic
  #jemimah's script is in /etc/init.d/Pwireless2
  chmod 755 /etc/init.d/Pwireless2 #make executable so it will run.
  #i want to run it right now, as a separate process (rc.services will ignore it)...
  /etc/init.d/Pwireless2 start &
 ;;
 net-setup.sh)
  /etc/rc.d/rc.network &
 ;;
 net_wiz_classic)
  #note, old wizard is located in /usr/local/net_setup.
  /usr/local/net_setup/etc/rc.d/rc.network &
 ;;
 sns) #100306
  /etc/rc.d/rc.network_basic #this only sets up interface 'lo'.
  /usr/local/simple_network_setup/rc.network &
 ;;
 *)
  #100628 shinobar: launch rc.network if eth0 is usable
  #this only sets up interface 'lo'...
  RCNETWORK=/etc/rc.d/rc.network_basic
  # eth0 usable?
  /sbin/ifconfig eth0 > /dev/null 2>&1 && [ -x /etc/rc.d/rc.network ] && RCNETWORK=/etc/rc.d/rc.network
  $RCNETWORK & 
 ;;
esac

fi

# Test if eth0 is realy up since some times fails after soft sleep
sleep 20
if [  "$TestEth"  != "" ] && [  "`iwgetid -a`"  != "" ] ; then
   exit 0
else
   cd /etc/powerd/postresume.d/
   ./reconnect.sh
fi
