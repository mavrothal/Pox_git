#!/bin/sh

XOVER=`cat /sys/class/dmi/id/product_version`
if [ "$XOVER" != "1" ] ; then
	gtkdialog-splash -fontsize large -bg hotpink -icon gtk-dialog-error -timeout 5 -text \
 "This app is only for the XO-1" &
	exit 0
fi

export Toucpad_configuration="
<window height-request=\"200\" title=\"XO-1 Touchpad Configuration\">
 <vbox>
 <frame>
  <hbox width-request=\"580\"> 
   <vbox>
   <text width-request=\"500\"><label>\"This is the default XO-1 touchpad (the jumpy one in first generation XO-1s :)\"</label></text>
  </vbox>
  <vbox>
    <button>
    <input file>/usr/local/lib/X11/mini-icons/XOpad_cap_48.png</input>
    <action>exec XOpad.orig</action>
   </button>
  </vbox>
  </hbox>
  

 <hbox width-request=\"580\">
 <vbox>
  <text width-request=\"500\"><label>\"This is for wide area resistive touchpad. You must use it with a stylus (no jumping though ;)\"</label></text>
  </vbox>
  <vbox>
   <button>
    <input file>/usr/local/lib/X11/mini-icons/XOpad_res_48.png</input>
    <action>exec XOpad.wide</action>
   </button>
   </vbox>
   </hbox> 
   </frame>
   <hbox><button ok></button></hbox>
 </vbox>
 </window>"
 
gtkdialog3 -p Toucpad_configuration -c

unset Toucpad_configuration
