#!/bin/sh
#
# $Id: make-dist.sh,v 1.9 2002/04/06 20:55:55 jsquyres Exp $
#
# For copyright information, please see the COPYING file in the
# top-level directory
#

srcdir="`pwd`"
distdir="$srcdir/$1"
want_srpms="$2"

############################################################################

if test "$want_srpms" = ""; then
    want_srpms="none"
fi

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
SRPM mode: $want_srpms

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
# Run autogen.sh and configure if necessary (yeah, that means always)
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
# Build the docs -- but not if we're not in an srpm-only mode
#

if test "$want_srpms" != "only"; then
    echo " - building installation docs"
    cd doc/installation
#make clean ps
#make mostlyclean pdf
    make clean pdf
    make mostlyclean

    echo " - building introduction docs"
    cd ../introduction
#make clean ps
#make mostlyclean pdf
    make clean pdf
    make mostlyclean

    cd ..

    echo " - removing source for docs in dist tarball"
    touch $distdir/doc/foo
    rm -rf $distdir/doc/*
    
    echo " - copying build docs into distdir/doc"
    cp installation/install.pdf $distdir/doc
    cp introduction/intro.pdf $distdir/doc
fi

#########################################################
# VERY IMPORTANT: Now go into the new distribution tree #
#########################################################

cd $distdir
umask 022

#
# Put in those headers.  Again, skip all this if we're in SRPM-only mode.
# 

echo "*** Inserting license headers..."

if test "$want_srpms" != "only"; then
    cd $distdir
    filelist=/tmp/oscar-license-filelist.$$
    rm -f $filelist
    cat > $filelist <<EOF
README
README.ia64
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

    if test "$OSCAR_BETA_VERSION" != "" -o "$OSCAR_ALPHA_VERSION" != ""; then
	echo " - This is a BETA version"
	file=/tmp/oscar-license.$$
	rm -f $file
	cat dist/beta-notice.txt dist/copyright-notice.txt > $file
	mv -f $file dist/copyright-notice.txt
	echo " - Ammended license notice ready"
    fi

    csh -f ./dist/insert-license.csh $filelist
    rm -rf $filelist
fi

rm -f dist/insert-license.*
rm -f dist/copyright-notice.txt
rm -f dist/beta-notice.txt

#
# Remove the configure/build system because it's not necessary in the
# distribution tarball
#

echo "*** Removing extra kruft"
rm -f aclocal.m4
rm -f configure configure.in
rm -rf dist
find . -name Makefile\* -exec rm -f {} \; -print

#
# Do we want just the SRPMs, or no SRPMs?
#

if test "$want_srpms" = "only"; then
    echo "*** Removing everything except SRPMs..."
    rm -f srpm.dirs other.dirs
    find . -name SRPMS > srpm.dirs
    find . -type d | grep -v SRPMS > other.dirs
    for dir in `cat srpm.dirs`; do
	d="$dir"
	
        # Make list of dirs not to remove (parents of SRPMS dirs)
	while test "$d" != "."; do
	    d="`dirname $d`"
	    if test "$d" != "."; then
		echo $d >> srpm.dirs
	    fi
	done
    done

    # Go compare one-by-one
    for possibly in `cat other.dirs`; do
	ok_to_remove=1
	for dont in `cat srpm.dirs`; do
	    if test "$dont" = "$possibly"; then
		ok_to_remove=0
	    fi
	done
	if test "$possibly" = "."; then
	    ok_to_remove=0
	fi
	if test "$ok_to_remove" = "1"; then
	    echo " - removing directory: $possibly"
	    rm -rf $possibly
	fi
    done
    rm -f srpm.dirs other.dirs install_cluster

    # Now go remove everything in the remaining directories that does
    # not contain "README", "COPYING", or end in ".rpm"
    for file in `find . -type f`; do
	if test "`echo $file | egrep 'README|COPYING'`" = "" -a \
	    "`echo $file | egrep '\.rpm$'`" = ""; then
	    echo " - removing file: $file"
	    rm -rf $file
	fi
    done
elif test "$want_srpms" = "including"; then
    echo "*** Leaving SRPMs included"
else
    echo "*** Removing SRPMs..."
    rm -rf packages/*/SRPMS
fi

#
# All done
#

cat <<EOF

============================================================================== 
OSCAR version $OSCAR_VERSION distribution created
SRPM mode: $want_srpms
 
Started: $start
Ended:   `date`
============================================================================== 
 
EOF

exit 0
