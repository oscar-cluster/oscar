#!/bin/sh
#
# $Id: update.sh,v 1.1 2001/08/20 23:08:07 jsquyres Exp $
#
# $COPYRIGHT$
#

#
# Convenience script for OSCAR maintainers to update their development
# tree.
#

# Helper subroutine for much of what follows

do_execute() {
    cmd_line="$*"
    eval $cmd_line
    if test "$?" != "0"; then
	cat <<EOF
=======================================================================
Update process ran into difficulties running the command:
    $cmd_line
Please check for errors and try running the updater again.
=======================================================================
EOF
	exit 1
    fi
}

# Make sure that we're in a known directory to execute from.  Check
# . and ..

if test -f configure.in -a -f dist/VERSION; then
    top_dir=.
elif test -f ../configure.in -a -f ../dist/VERSION; then
    top_dir=..
else
    cat <<EOF
=======================================================================
Please execute this script only from the top-level directory of your
OSCAR development tree.
=======================================================================
EOF
    exit 1
fi

# Go to the top-level directory

cd $top_dir

# First, update CVS

do_execute cvs update -P -d

# Then re-run automake and friends

do_execute aclocal
do_execute autoconf
do_execute automake -a
do_execute ./configure

# Now run "make" to download any new binary files

do_execute make

# That's all she wrote

cat <<EOF

----------------------------------------------------
The OSCAR development tree was successfully updated.
----------------------------------------------------

EOF
exit 0
