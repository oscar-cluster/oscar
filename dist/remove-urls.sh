#!/bin/sh
#
# $COPYRIGHT$
#
# $Id: remove-urls.sh,v 1.1 2001/08/28 00:50:25 jsquyres Exp $
#

files="$*"

if test "$files" != ""; then
  for file in $files; do
    str="rm -f `basename $file`"
    echo $str
    eval $str
  done
fi

exit 0
