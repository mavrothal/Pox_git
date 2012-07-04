#!/bin/sh

# check puppy mode and add a sync of the pupysave before suspend
#. /etc/rc.d/PUPSTATE
#if [ $PUPMODE = "13" ] || [ $PUPMODE = "7" ] ; then
#        snapmergepuppy
#fi

touch /tmp/sleeping.now
sync
sleep 3
exit 0
