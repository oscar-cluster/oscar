#!/bin/sh
#
# Copyright (c) 2002 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the LICENSE file in the top level directory of the
# OSCAR source distribution.
#
# $Id: autogen.sh,v 1.3 2002/10/26 12:05:05 jsquyres Exp $
#

cmd="autoconf -o setup setup.ac"
echo $cmd
eval $cmd
if test "$?" != 0; then
    echo "autoconf failed -- aborting"
    exit 1
fi

ac_path="`which autoconf`"
dir="`dirname $ac_path`"
dir="`dirname $dir`/share"
dirs="`/bin/ls -d $dir/automake* 2>/dev/null`"
if test "$dirs" = ""; then
    echo "can't find automake!"
    exit 1
fi
dir="`echo $dirs | awk '{print $1}'`"
if test -d $dir; then
    files="config.guess config.sub install-sh"
    for file in $files; do
	if test -f $dir/$file; then
	    cmd="cp -f $dir/$file ."
	    echo $cmd
	    eval $cmd
	else
	    echo "WARNING: did not find $file in $dir"
	    echo "WARNING: supplemental file not copied"
	fi
    done
else
    echo "WARNING: $dir does not seem to exist"
    echo "WARNING: did not copy supplemental files"
    exit 1
fi

exit 0
