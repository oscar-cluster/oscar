#!/bin/sh
#
# Copyright (c) 2002-2005 The Trustees of Indiana University.  
#                         All rights reserved.
# Copyright (c) 2006 Erich Focht
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

srcdir="`pwd`"
distdir="$srcdir/$1"
want_srpms="$2"
OSCAR_VERSION="$3"
OSCAR_SVN_R="$4"
WANT_CORE_ONLY="$5"

############################################################################

# We should only allow "make dist" from an SVN checkout

if test ! -f autogen.sh; then
    cat <<EOF
***************************************************************************
You can only "make dist" from within a Subversion checkout.  "make dist"
is not supported from OSCAR distribution tarballs.
***************************************************************************
EOF
    exit 1
fi

############################################################################

# we can catch some hard (but possible) to do mistakes by looking at
# our tree's revision number, but only if we are in the source tree.
# Otherwise, use what configure told us, at the cost of allowing one
# or two corner cases in (but otherwise VPATH builds won't work)
svn_r=$OSCAR_SVN_R
if test -d .svn; then
    svn_r="r`svnversion .`"
fi

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

svn_r=
if test "`echo $OSCAR_SVN_R | cut -c1`" = "r"; then
    svn_r="r`svnversion .`"
fi

#
# Build the docs
#

if test -n "$OSCAR_SKIP_DOCS" -o "$want_srpms" = "only"; then
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

#
# See if we need to update the version file with the current SVN
# revision number.  Do this *before* entering the distribution tree to
# solve a whole host of problems with VPATH (since srcdir may be
# relative or absolute)
#
cur_svn_r="`grep '^svn_r' ${distdir}/VERSION | cut -d= -f2`"
if test "$cur_svn_r" = "-1"; then
    sed -e 's/^svn_r=.*/svn_r='$svn_r'/' "${distdir}/VERSION" > "${distdir}/version.new"
    cp "${distdir}/version.new" "${distdir}/VERSION"
    rm -f "${distdir}/version.new"
    # need to reset the timestamp to not annoy AM dependencies
    touch -r "${srcdir}/VERSION" "${distdir}/VERSION"
    echo "*** Updated VERSION file with SVN r number"
else
    echo "*** Did NOT updated VERSION file with SVN r number"
fi

#########################################################
# VERY IMPORTANT: Now go into the new distribution tree #
#########################################################

cd $distdir
umask 022

#
# Remove unwanted files
#

find . -name Makefile.am -o -name Makefile.in | xargs rm -f
rm -f acinclude.m4 aclocal.m4 configure configure.in

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

if test "$OSCAR_GREEK_VERSION" != ""; then
    echo " - This is an unofficial release version"
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
# Make regular, extra crispy, or secret sauce
#

echo want_srpms: $want_srpms
if test "$want_srpms" = "regular" -o -z "$want_srpms"; then
    echo REGULAR

    # Whack all the SRPMS dirs

    for dir in `find packages -name SRPMS -print`; do
        echo " - Removing: $dir"
        rm -rf $dir
    done

    # Ditch SRPMS from all Makefile.am's

    for file in `find packages -name Makefile.am -print`; do
        echo " - Updating: $file"

        rm -f $file.new.$$
        sed -e 's/SRPMS//g' $file > $file.new.$$
        cp $file.new.$$ $file
        rm $file.new.$$
    done

    # Ditch SRPM Makefiles from the m4 file

    egrep -v /SRPMS/ dist/config_files_list.m4 > newfile.$$
    cp newfile.$$ dist/config_files_list.m4
    rm -f newfile.$$

    # Now re-run the tools to get everything proper in the configure
    # script

    echo " - Re-running aclocal"
    aclocal
    echo " - Re-running autoconf"
    autoconf
    echo " - Re-running automake"
    automake -a --copy
    rm -rf autom4te.cache

elif test "$want_srpms" = "only"; then
    echo ONLY
    rm -rf *m4 autogen* autom4te* config* dist* doc* images* install_cluster
    rm -rf lib Makefile* oscarsamples scripts share src testing
    cd packages
    rm Makefile.* package.dtd
    for dir in `/bin/ls`; do
        echo checking dir: $dir
        if test -d "$dir" -a "$dir" != "." -a "$dir" != ".."; then
            echo removing all but SRPMS from package $dir
            cd $dir
            for subdir in `/bin/ls`; do
                echo checking subdir: $subdir
                if test "$subdir" != "." -a \
                    "$subdir" != ".." -a "$subdir" != "SRPMS"; then
                    rm -rf $subdir
                fi
            done
            cd ..

            # If there's nothing left (i.e., if there was no SRPMS),
            # then just whack the dir

            if test ! -d $dir/SRPMS; then
                rm -rf $dir
            else
                rm -f $dir/SRPMS/Makefile* > /dev/null 2>&1
            fi
        fi
    done
    cd ..
fi

if test "$WANT_CORE_ONLY" = "yes"; then
  # We remove packages which are not core packages.
  # Four kinds of packages are available: core, base, included, third-party
  # It should be better to not add them (same thing for SRPMS) but no time to do it right now

  # We remove first third-party packages
  echo "Removing third-party packages"
  cd packages
  for dir in `/bin/ls`; do
    echo checking dir: $dir
    if test -d "$dir" -a "$dir" != "." -a "$dir" != ".."; then
      cd $dir
      ret=`grep "third-party" config.xml`
      echo $ret
      cd ..
      if test "$ret" != ""; then
        echo "Deleting third-party package $dir"
        rm -rf $dir
      fi
    fi
  done
  cd ..

  # We remove then included packages 
  echo "Removing included packages"
  cd packages
  for dir in `/bin/ls`; do
    echo checking dir: $dir
    if test -d "$dir" -a "$dir" != "." -a "$dir" != ".."; then
      cd $dir
      ret=`grep "included" config.xml`
      echo $ret
      cd ..
      if test "$ret" != ""; then
        echo "Deleting included package $dir"
        rm -rf $dir
      fi
    fi
  done
  cd ..
fi

cd $srcdir
./dist/split-distro.sh `basename $distdir` $OSCAR_VERSION

#
# All done
#

cat <<EOF

============================================================================== 
OSCAR version $OSCAR_VERSION distribution created
SRPMs: $want_srpms
Documentation: $doc_mode
 
Started: $start
Ended:   `date`
============================================================================== 
 
EOF

exit 0
