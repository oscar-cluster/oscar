#!/bin/sh

#
#   $Id: systemimager-init-script.patch.sh,v 1.5 2003/02/13 16:04:32 brianfinley Exp $
#

PATCH="${OSCAR_PACKAGE_HOME}/scripts/${PATCH}"

cd /etc/init.d 
patch -p0 < ${PATCH}
if [ "$?" != "0" ]; then
    echo "Patch of /etc/init.d/systemimager failed!"
    exit 1
fi

exit 0

### Patch below ###

--- systemimager.orig	2003-02-11 13:21:22.000000000 -0600
+++ systemimager	2003-02-11 13:22:29.000000000 -0600
@@ -31,7 +31,7 @@
 ### END INIT INFO
 
 
-PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
+export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
 NAME=rsync
 OPTIONS="--daemon --config=/etc/systemimager/rsyncd.conf"
 DAEMON=`which $NAME` || exit 0
