#! /bin/sh 
#
# $Id: autogen.sh,v 1.1 2001/12/19 02:36:54 jsquyres Exp $
#
# This script is run on developer copies of OSCAR -- *not*
# distribution tarballs.
#

#
# Some helper functions
#

test_for_existence() {
    prog="$1"
    foo="`$prog --version`"
    if test "$?" != 0; then
	cat <<EOF

You must have GNU autoconf, automake, and libtool installed to build
the developer's version of LAM/MPI.  You can obtain these packages
from ftp://ftp.gnu.org/gnu/.

EOF
	# Stupid emacs: '
	exit 1
    fi
}

run_and_check() {
    progs="$*"
    echo "$progs"
    eval $progs
    if test "$?" != 0; then
	cat <<EOF

It seems that the execution of "$progs" has failed.
I am gonna abort.  :-(

This may be caused by an older version of one of the required
packages.  Please make sure you are using at least the following
versions:

GNU Autoconf 2.52
GNU Automake 1.5
GNU Libtool  1.4

EOF
	exit 1
    fi
}

#
# Are we in the right dir?
#

if test -f COPYING -a -f configure.in ; then
    bad=0
else
    cat <<EOF

You must run this script from the top-level OSCAR directory.

EOF
    exit 1
fi

test_for_existence autoconf
test_for_existence automake
test_for_existence libtool

#
# Run them all
#

rm -f config/config.guess
rm -f config/config.sub
rm -f config/depcomp
rm -f config/install-sh
rm -f config/ltconfig
rm -f config/ltmain.sh
rm -f config/missing
rm -f config/mkinstalldirs

run_and_check aclocal
# OSCAR doesn't (yet) need autoheader
#run_and_check autoheader
run_and_check autoconf
run_and_check automake -a

exit 0
