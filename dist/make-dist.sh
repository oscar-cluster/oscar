#!/bin/sh
#
# $Id: make-dist.sh,v 1.5 2002/01/15 03:20:50 jsquyres Exp $
#
# $COPYRIGHT$
#

srcdir="`pwd`"
distdir="$srcdir/$1"

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

#########################################################
# VERY IMPORTANT: Now go into the new distribution tree #
#########################################################

cd $distdir
umask 022

#
# Put in those headers
#
 
echo "*** Inserting license headers..."

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

rm -f dist/insert-license.*
rm -f dist/copyright-notice.txt
rm -f dist/beta-notice.txt

#
# Remove the configure/build system because it's not necessary in the
# distribution tarball
#

rm -f aclocal.m4
rm -f configure configure.in
rm -rf dist
find . -name Makefile\* -exec rm -f {} \; -print

#
# All done
#

cat <<EOF

============================================================================== 
OSCAR version $OSCAR_VERSION distribution created
 
Started: $start
Ended:   `date`
============================================================================== 
 
EOF

exit 0
