#!/bin/sh
#
# $COPYRIGHT$
#
# $Id: download-files.sh,v 1.1 2001/08/20 23:08:07 jsquyres Exp $
#

top_srcdir="$1"
shift
files="$*"

# Get the results from configure

prog="$top_srcdir/dist/programs.sh"
if test -f $prog; then
    . $prog
else
    echo "I can't find dist/programs.sh!"
    exit 1
fi

# Check for each file, and if we don't have it, download it.

for file in $files; do
    b="`basename $file`"
    if test ! -f $b; then
	$WGET $file
    fi
done

exit 0
