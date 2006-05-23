#!/bin/bash
#
# Copyright (c) 2006 Erich Focht
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#


usage () {
    echo "Usage:"
    echo "  $0 [--base] [--srpms] [--docs] [--no-repos] [--distro D-V-A]"
    echo "     [--distro D2-V2-A2] [--all]"
    exit 1
}

while [ -n "$1" ]; do
   case $1 in
       --base)
	   shift
	   BUILD_BASE=1
	   ;;
       --srpms)
	   shift
	   BUILD_SRPMS=1
	   ;;
       --docs)
	   shift
	   BUILD_DOCS=1
	   ;;
       --no-repos)
	   shift
	   NO_REPOS=1
	   ;;
       --distro)
	   shift
	   [ -z "$1" ] && usage
	   DISTROS="$DISTROS $1"
	   shift
	   ;;
       --all)
	   shift
	   BUILD_BASE=1
	   BUILD_SRPMS=1
	   BUILD_DOCS=1
	   ;;
       *)
	   usage
	   ;;
   esac
done


RUNDIR=`pwd`
if [ `basename $RUNDIR` != "dist" ]; then
    echo "***  You should be running this program from within the dist directory! ***"
    exit 1
fi

# set srcdir to parent directory
srcdir=`dirname $RUNDIR`

svn info $srcdir
if [ $? -ne 0 ]; then
    echo "svn info returned an error. This is maybe not a SVN tree!"
    exit 1
fi
OSCAR_VERSION=`$RUNDIR/get-oscar-version.sh $srcdir/VERSION`

############################################################################

start=`date`
cat <<EOF

============================================================================== 
Creating OSCAR distribution version $OSCAR_VERSION

In directory: `pwd`
Started: $start
============================================================================== 
 
EOF

umask 022
cd $srcdir/..
distbase=oscar-$OSCAR_VERSION
distdir=`pwd`"/$distbase"


#
# Copy the source tree in economic way, by using hardlinks
#

if [ -d "$distdir" ]; then
    echo "!!! $distdir already exists !!!"
    exit 1
fi
cp -rl $srcdir $distdir
# remove .svn directories
(cd $distdir; find . -name .svn | xargs rm -rf)



#
# Switch into the distribution directory in order to protect the source
#
cd $distdir
export OSCAR_HOME=`pwd`


# Detect this host's packaging mechanism
distro_pkg () {
    perl -e "
	use lib \"$OSCAR_HOME/lib\";
	use OSCAR::OCA::OS_Detect;
	\$os=OSCAR::OCA::OS_Detect::open();
	print \$os->{pkg}; "
}


if [ -n "$BUILD_BASE" ]; then
    # Build Qt tools and docs

    cat <<EOF
==========================================================
         Building Qt related programs in src/
==========================================================
EOF
    cat <<EOF
=============================================================
 Installing perl-Qt, will need it for repository preparation
=============================================================
EOF
    scripts/install_prereq --verbose --dumb share/prereqs/perl-Qt
    cd src
    make || exit 1
    cd ..
fi


if [ -n "$BUILD_DOCS" ]; then

    cat <<EOF
==========================================================
         Building docs ...
==========================================================
EOF
    cd doc

    #
    # Install docs
    #

    echo " - building installation docs"
    cd installation
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
    mv installation/install.pdf installation/quick_install.pdf .
    mv user/user.pdf .
    if test ! -f $distdir/doc/install.pdf -o \
	    ! -f $distdir/doc/quick_install.pdf -o \
	    ! -f $distdir/doc/user.pdf; then
	cat <<EOF

WARNING: doc/user.pdf, doc/install.pdf, and/or doc/quick_install.pdf 
WANRING: don't seem to exist.  Aborting...

EOF
	exit 1
    fi

    #
    # actually this one should build the docs, but some of them fail
    # 
    #make || exit 1
    cd ..
fi

#
# Remove unwanted files
#

find . -name Makefile.am -o -name Makefile.in -o -name Makefile \
       -o -name .oscar_made_makefile_am -o -name '*~' | xargs rm -f
rm -f acinclude.m4 aclocal.m4 configure configure.in


if [ -n "$BUILD_BASE" ]; then
    #
    # Put in those headers.
    #
    echo "************************************"
    echo "*** Inserting license headers... ***"
    echo "************************************"

    filelist=`mktemp`
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

    newlist=`mktemp`
    grep -l '\$COPYRIGHT\$' `cat $filelist` > $newlist

    cat <<EOF
==================================================
Replacing COPYRIGHT in files:
`cat $newlist`
==================================================
EOF

    # the insert license routine is not smart enough with hardlinks
    # so re-create these files with new inodes
    for f in `cat $newlist`; do
	cp $f ${f}_new
	rm -f $f
	mv ${f}_new $f
    done

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

    csh -f ./dist/insert-license.csh $newlist
    rm -f $filelist $newlist

    #
    # Substitute in the current version number to some top-level text
    # files
    #

    cat > $filelist <<EOF
README
EOF
    for file in `cat $filelist`; do
	sed -e s/OSCARVERSION/$OSCAR_VERSION/g $file > $file.out
	mv $file.out $file
    done
    rm -f $filelist

    rm -f dist/insert-license.*
    rm -f dist/copyright-notice.txt
    rm -f dist/beta-notice.txt
fi

if [ -z "$NO_REPOS" ]; then

    cat <<EOF
==========================================================
 Installing yume, will need it for repository preparation
==========================================================
EOF

    PKGMGR=`distro_pkg`
    if [ "$PKGMGR" = "rpm" ]; then
	scripts/install_prereq --verbose --dumb \
	    share/prereqs/packman packages/yume
    elif [ "$PKGMGR" = "rpm" ]; then
	scripts/install_prereq --verbose --dumb \
	    share/prereqs/packman packages/rapt
    else
	echo "Unsupported package manager $PKGMGR"
	exit 1
    fi

    # build repositories
    TGTDIR="$distdir/repo"
    mkdir -p $TGTDIR
    if [ -z "$DISTROS" ]; then
	DISTROS="
common-rpms
fc-3-i386
fc-3-x86_64
fc-4-i386
fc-5-i386
fc-5-x86_64
mdv-2006-i386
rhel-3-i386
rhel-3-ia64
rhel-3-x86_64
rhel-4-i386
rhel-4-ia64
rhel-4-x86_64
"
    fi

    cat <<EOF
==========================================================
         Building OSCAR package repositories
==========================================================
EOF

    cd scripts
    for distro in $DISTROS; do
	echo " - building package repository for $distro"
	./build_oscar_repo --distro $distro --target $TGTDIR
	# compress repository and delete it
	echo " - compressing repository $distro"
	(cd $TGTDIR; \
	    tar czf ../../oscar-repo-$distro-$OSCAR_VERSION.tar.gz $distro; \
	    rm -rf $distro)
    done
    rm -rf $TGTDIR

fi

cd $distdir/..

if [ -n "$BUILD_SRPMS" ]; then
    cat <<EOF
==========================================================
         Building OSCAR SRPMs tarball
==========================================================
EOF
    # build filelist for srpms
    srpms=`mktemp`
    find $distbase -type d -a -name SRPMS > $srpms
    tar -cz --files-from $srpms -f oscar-srpms-$OSCAR_VERSION.tar.gz

fi

if [ -n "$BUILD_BASE" ]; then
    cat <<EOF
==========================================================
         Building OSCAR base tarball
==========================================================
EOF
    #
    # remove all distro directories except those of yume, rapt and packman
    #
    distrodirs=`mktemp`
    find $distbase -type d -a -name distro | \
	egrep -v "/(yume|rapt|packman)/distro" > $distrodirs
    #
    # remove the distro directories (files are in the repository)
    #
    rm -rf `cat $distrodirs`

    #
    # remove SRPMs
    #
    if [ -z "$srpms" ]; then
	srpms=`mktemp`
	find $distbase -type d -a -name SRPMS > $srpms
    fi
    rm -rf `cat $srpms`

    #
    # What is left over is the OSCAR base distribution
    #
    tar -czf oscar-base-$OSCAR_VERSION.tar.gz $distbase
fi

rm -rf $distbase

[ -n "$srpms" ] && rm -f $srpms
[ -n "$distrodirs" ] && rm -f $distrodirs


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
