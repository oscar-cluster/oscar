#!/bin/sh
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id: make-dist.sh,v 1.24 2003/07/04 14:20:48 jsquyres Exp $
#

srcdir="`pwd`"
distdir="$srcdir/$1"

############################################################################

OSCAR_VERSION="`sh dist/get-oscar-version.sh $srcdir --full`"
OSCAR_MAJOR_VERSION="`sh dist/get-oscar-version.sh $srcdir --major`"
OSCAR_MINOR_VERSION="`sh dist/get-oscar-version.sh $srcdir --minor`"
OSCAR_RELEASE_VERSION="`sh dist/get-oscar-version.sh $srcdir --release`"
OSCAR_ALPHA_VERSION="`sh dist/get-oscar-version.sh $srcdir --alpha`"
OSCAR_BETA_VERSION="`sh dist/get-oscar-version.sh $srcdir --beta`"

if test "$distdir" = ""; then
    echo "Must supply distdir as argv[1] -- aborting"
    exit 1
fi

MAKEFILE_OSCAR_VERSION="`egrep ^OSCAR_VERSION Makefile | awk '{ print $3 }'`"

if ! test "$OSCAR_VERSION" = "$MAKEFILE_OSCAR_VERSION" ; then
  echo "Version in Makefile and version in VERSION file do not match!"
  echo "This means the VERSION file has changed since configure"
  echo "was last run.  Please check VERSION file and rerun configure"
  echo "Aborting!"
  exit 1
fi

start=`date`
cat <<EOF

============================================================================== 
Creating OSCAR distribution version $OSCAR_VERSION

In directory: `pwd`
Started: $start
============================================================================== 
 
EOF

#
# STILL IN THE SOURCE TREE...
#
# We need to build the docs here in the source tree because we can run
# autogen.sh and configure here; we can't do that in the disttree.
#

#
# Run autogen.sh and configure if necessary
#

if ! test -f configure; then
    echo " - Running GNU auto* tools"
    ./autogen.sh
fi
if ! test -f Makefile; then
    echo " - Running configure"
    ./configure
fi

#
# Build the docs
#

if test -n "$OSCAR_SKIP_DOCS"; then
    doc_mode="SKIPPED"
    cat <<EOF

WARNING: Skipping OSCAR doc build because $OSCAR_SKIP_DOCS is set

EOF

else
    doc_mode="built"

    #
    # Install docs
    #

    echo " - building installation docs"
    cd doc/installation
    make clean pdf
    if test "$?" != "0"; then
	cat <<EOF

WARNING: It seems like install.pdf didn't build properly.  Aborting...

EOF
	exit 1
    fi
    make mostlyclean

    #
    # User docs
    #

    echo " - building user docs"
    cd ../user
    make clean pdf
    if test "$?" != "0"; then
	cat <<EOF

WARNING: It seems like user.pdf didn't build properly.  Aborting...

EOF
	exit 1
    fi
    make mostlyclean
    ls -l

    cd ..

    #
    # Copy the docs over; ensure that they were generated correctly
    #

    echo " - copying build docs into distdir/doc"
    cp installation/install.pdf installation/quick_install.pdf $distdir/doc
    cp user/user.pdf $distdir/doc
    if test ! -f $distdir/doc/install.pdf -o \
	    ! -f $distdir/doc/quick_install.pdf -o \
	    ! -f $distdir/doc/user.pdf; then
	cat <<EOF

WARNING: doc/user.pdf, doc/install.pdf, and/or doc/quick_install.pdf 
WANRING: don't seem to exist.  Aborting...

EOF
	exit 1
    fi
fi

#########################################################
# VERY IMPORTANT: Now go into the new distribution tree #
#########################################################

cd $distdir
umask 022

#
# Put in those headers.  
# 

echo "*** Inserting license headers..."

cd $distdir
filelist=/tmp/oscar-license-filelist.$$
rm -f $filelist
cat > $filelist <<EOF
README
EOF
find dist -type f -print >> $filelist
find doc -type f -print | egrep -v '.png$' >> $filelist
find images -type f -print | egrep -v '.gif$' >> $filelist
find lib -type f -print >> $filelist
find oscarsamples -type f -print >> $filelist
find packages -type f -print | egrep -v '.rpm$' >> $filelist
find scripts -type f -print >> $filelist
find testing -type f -print >> $filelist
    
#
# If this is a beta, prepend the beta notice to the license.  
#

if test "$OSCAR_BETA_VERSION" != "0" -o "$OSCAR_ALPHA_VERSION" != "0"; then
    echo " - This is a BETA version"
    file=/tmp/oscar-license.$$
    rm -f $file
    cat dist/beta-notice.txt dist/copyright-notice.txt > $file
    mv -f $file dist/copyright-notice.txt
    echo " - Ammended license notice ready"
fi

csh -f ./dist/insert-license.csh $filelist
rm -f $filelist

#
# Substitute in the current version number to some top-level text
# files
#

cat > $filelist <<EOF
README
EOF
for file in `cat $filelist`; do
    sed -e s/OSCARVERSION/$OSCAR_VERSION/g $file > $file.out
    cp $file.out $file
    rm -f $file.out
done
rm -f $filelist

rm -f dist/insert-license.*
rm -f dist/copyright-notice.txt
rm -f dist/beta-notice.txt

#
# All done
#

cat <<EOF

============================================================================== 
OSCAR version $OSCAR_VERSION distribution created
Documentation: $doc_mode
 
Started: $start
Ended:   `date`
============================================================================== 
 
EOF

exit 0
