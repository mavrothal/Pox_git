#!/bin/sh

# check puppy mode
#. /etc/rc.d/PUPSTATE

# add a sync of the pupysave before suspend
#if [ $PUPMODE = "13" ] || [ $PUPMODE = "7" ] ; then
#        snapmergepuppy
#fi
touch /tmp/sleeping.now
sync
sleep 3
exit 0
