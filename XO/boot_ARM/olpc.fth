\ olpc.fth

visible

\ set machine macros
bundle-suffix$     " MACHINE"      $set-macro

: set-path-macros  ( -- )

   \ Set DN to the device that was used to boot this script
   " /chosen" find-package  if                       ( phandle )
      " bootpath" rot  get-package-property  0=  if  ( propval$ )
         get-encoded-string                          ( bootpath$ )
         [char] \ left-parse-string  2nip            ( dn$ )
         dn-buf place                                ( )
      then
   then
;


\ We check if we are booting from USB or SDcard to specify device-specific parameters

: dn-contains?  ( $ -- flag )  " ${DN}" expand$  sindex 0>=  ;
: usb?    ( -- flag )  " /usb"     dn-contains?  ;
: sd?     ( -- flag )  " /sd"      dn-contains?  ;
: slot1?  ( -- flag )  " /disk@1"  dn-contains?  ;

: olpc-fth-boot-me  ( -- )
   set-path-macros

   \ specify where to find base sfs.  
   usb?  if
        " sda1"
   else
   	sd?  if
         slot1?  if
            " mmcblk1p1"  \ external SD card
         else
            " mmcblk0p1"  \ Internal SD card
         then
      then
   then
   " PD" $set-macro
   
\ set kernel command line
" fbcon=font:SUN12x22 console=ttys2,115200 console=tty0 waitdev=5 basesfs=device:${PD}:/fd-arm.sfs"  expand$ to boot-file

\ choose initramfs
" ${DN}\boot\initrd.${MACHINE}"   expand$ to ramdisk

\ choose kernel
" ${DN}\boot\vmlinuz.${MACHINE}"       expand$ to boot-device
   
   boot
;
olpc-fth-boot-me
