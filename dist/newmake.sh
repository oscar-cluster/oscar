#!/bin/bash
#
# Copyright (c) 2006 Erich Focht
#
# Copyright (c) 2007 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#


cleanup () {
    # remove temporary files
    for n in "$TFILES"; do
	[ -f $n ] && rm -f $n
    done
}

bail_out () {
    local ERR=$1
    cleanup
    exit $ERR
}

usage () {
    echo "Usage:"
    echo "  $0 [--base] [--srpms] [--docs] [--all-repos] [--nightly] [--distro D-V-A] \ "
    echo "     [--distro D2-V2-A2] [--all] [--repo-target DIR] \ "
    echo "     [--install-target DIR]"
    bail_out 1
}

get_tfile () {
    local name=`mktemp`
    TFILES="$TFILES $name"
    echo $name
}

message () {
    local string="$*"
    echo "====================================================="
    echo $string
    echo "====================================================="
}

trap bail_out INT HUP QUIT

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
       --all-repos)
	   shift
	   ALL_REPOS=1
	   ;;
       --nightly)
	   shift
       NIGHTLY=1
	   ;;
       --distro)
	   shift
	   [ -z "$1" ] && usage
	   DISTROS="$DISTROS $1"
	   shift
	   ;;
       --install-target)
	   shift
	   [ -z "$1" ] && usage
	   INSTALL_TARGET="$1"
	   shift
	   ;;
       --repo-target)
	   shift
	   [ -z "$1" ] && usage
	   REPO_TARGET="$1"
	   shift
	   ;;
       --all)
	   shift
	   BUILD_BASE=1
	   BUILD_SRPMS=1
	   BUILD_DOCS=1
	   ALL_REPOS=1
	   ;;
       *)
	   usage
	   ;;
   esac
done


RUNDIR=`pwd`
if [ `basename $RUNDIR` != "dist" ]; then
    echo "***  You should be running this program from within the dist directory! ***"
    bail_out 1
fi

# set srcdir to parent directory
srcdir=`dirname $RUNDIR`

umask 022
cd $srcdir
OSCAR_VERSION=`scripts/get-oscar-version.sh VERSION`
OSCAR_GREEK_VERSION=`scripts/get-oscar-version.sh VERSION --greek`
OSCAR_SVN_VERSION=`scripts/get-oscar-version.sh VERSION --svn`

nightly_date=`date '+%Y%m%d'`
if [ -n "$NIGHTLY" ]; then
    sed -e s/^svn_r=.*/svn_r="$OSCAR_SVN_VERSION"nightly-"$nightly_date"/g VERSION > VERSION.new
	mv VERSION.new VERSION
    exit 0
fi

############################################################################

start=`date`
cat <<EOF

============================================================================== 
Creating OSCAR distribution version $OSCAR_VERSION

In directory: `pwd`
Started: $start
============================================================================== 
 
EOF

#
# We operate mainly one directory level above the checkout
#
cd ..
distbase=oscar-$OSCAR_VERSION
distdir=`pwd`"/$distbase"


#
# Copy the source tree in economic way, by using hardlinks
#

if [ -d "$distdir" ]; then
    echo "!!! $distdir already exists !!!"
    bail_out 1
fi
cp -rl $srcdir $distdir
#
# Remove unwanted files
# Don't remove Makefiles, yet, as we still need them.
#
( cd $distdir; find . -name .svn -type d | xargs rm -rf;
    find . -name '*~' | xargs rm -f;
    [ -d tmp ] && rm -rf tmp )

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

    message "Building Qt related programs in src/"
    message "Installing perl-Qt, will need it for repository preparation"

    scripts/install_prereq --verbose --dumb share/prereqs/perl-Qt
    cd src
    make || bail_out 1
    cd ..
fi

# docs building is switched off now
# docs will be built out of the docuwiki repository, only
BUILD_DOCS=""

if [ -n "$BUILD_DOCS" ]; then

    message "  Building docs ..."
    cd doc

    #
    # Install docs
    #

    echo " - building installation docs"
    cd installation
    make clean pdf
    if test "$?" != "0"; then
	message "WARNING: It seems like install.pdf didn't build properly.  Aborting..."
	bail_out 1
    fi
    make mostlyclean

    #
    # User docs
    #

    echo " - building user docs"
    cd ../user
    make clean pdf
    if test "$?" != "0"; then
	message "WARNING: It seems like user.pdf didn't build properly.  Aborting..."
	bail_out 1
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
	message "WARNING: doc/user.pdf, doc/install.pdf, and/or doc/quick_install.pdf don't seem to exist.  Aborting..."
	bail_out 1
    fi

    #
    # actually this one should build the docs, but some of them fail
    # 
    #make || bail_out 1
    cd ..
fi


if [ -n "$BUILD_BASE" ]; then
    #
    # Put in those headers.
    #
    message "*** Inserting license headers... ***"

    filelist=`get_tfile`
    echo README > $filelist

    find dist -type f -print >> $filelist
    find doc -type f -print | egrep -v '.png$' >> $filelist
    find images -type f -print | egrep -v '.gif$' >> $filelist
    find lib \( -type f -o -type l \) -print >> $filelist
    find oscarsamples -type f -print >> $filelist
    find packages -type f -print | egrep -v '.rpm$' >> $filelist
    find scripts -type f -print >> $filelist
    find testing -type f -print >> $filelist

    newlist=`get_tfile`
    grep -l '\$COPYRIGHT\$' `cat $filelist` > $newlist

    message "Replacing COPYRIGHT in files:"`cat $newlist`

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

    #
    # Fill in SVN revision in VERSION file
    #

    if test "$OSCAR_SVN_VERSION" != ""; then
        sed -e s/^svn_r=.*/svn_r=$OSCAR_SVN_VERSION/g VERSION > VERSION.new
	    mv VERSION.new VERSION
    fi

    csh -f ./dist/insert-license.csh $newlist
    rm -f $filelist $newlist

    #
    # Substitute in the current version number to some top-level text
    # files
    #

    echo README > $filelist

    for file in `cat $filelist`; do
	sed -e s/OSCARVERSION/$OSCAR_VERSION/g $file > $file.out
	mv $file.out $file
    done
    rm -f $filelist

    rm -f dist/insert-license.*
    rm -f dist/copyright-notice.txt
    rm -f dist/beta-notice.txt
fi

if [ -n "$DISTROS" -o -n "$ALL_REPOS" ]; then

    message "Installing yume, will need it for repository preparation"

    PKGMGR=`distro_pkg`
    if [ "$PKGMGR" = "rpm" ]; then
	scripts/install_prereq --verbose --dumb \
	    share/prereqs/packman packages/yume
    elif [ "$PKGMGR" = "deb" ]; then
	scripts/install_prereq --verbose --dumb \
	    share/prereqs/packman packages/rapt
    else
	echo "Unsupported package manager $PKGMGR"
	bail_out 1
    fi

    # build repositories
    if [ -n "$REPO_TARGET" ]; then
	# repository will be built directly in the given directory
	# no tar will be built!
	TGTDIR=$REPO_TARGET
    else
	# build repositories in temporary directory
	# build tars!
	TGTDIR="$distdir/repo"
	mkdir -p $TGTDIR
    fi
    if [ -n "$ALL_REPOS" ]; then
	DISTROS="common-rpms \
            rhel-4-i386 rhel-4-x86_64 rhel-5-i386 rhel-5-x86_64 \
            fc-7-i386 fc-7-x86_64 fc-8-i386 fc-8-x86_64 \
            fc-9-x86_64 \
            suse-10.2-x86_64 suse-10.3-x86_64 \
            ydl-5-ppc64"
    fi

    message ">> Building OSCAR package repositories <<"

    cd scripts
    for distro in $DISTROS; do
	echo " - building package repository for $distro"
	./build_oscar_repo --distro $distro --target $TGTDIR --remove
	if [ $? -ne 0 ]; then
	    echo "ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR ERROR"
	    echo "OSCAR repository build failed! Please check the output!"
	    exit 11
	fi
	if [ -z "$REPO_TARGET" ]; then
	    # compress repository and delete it
	    echo " - compressing repository $distro"
	    (cd $TGTDIR; \
	     tar czf ../../oscar-repo-$distro-$OSCAR_VERSION.tar.gz $distro; \
	     rm -rf $distro)
	fi
    done
    [ -z "$REPO_TARGET" ] && rm -rf $TGTDIR

fi

cd $distdir/..


if [ -n "$BUILD_BASE" ]; then
    if [ -z "$INSTALL_TARGET" ]; then
	message ">> Building OSCAR base tarball in "`pwd`
    else
	message ">> Installing OSCAR base into $INSTALL_TARGET"
    fi

    afiles=`get_tfile`
    find $distbase \( -type f -o -type l \) > $afiles

    bfiles=`get_tfile`
    # filter out all distro directories except for yume, rapt, packman
    egrep -v  "(share/prereqs|packages)/.*/(distro|SRPMS)/" <$afiles >$bfiles
    egrep "/(yume|rapt|packman)/distro/" <$afiles >>$bfiles
    egrep -v "/Makefile" <$bfiles | sort >$afiles

    #
    # What is left over is the OSCAR base distribution
    #
    if [ -n "$INSTALL_TARGET" ]; then
	if [ ! -d "$INSTALL_TARGET" ]; then
	    echo "Target directory $INSTALL_TARGET does not exist."
	    echo "Trying to create it..."
	    mkdir -p $TARGET_DIR || bail_out 1
	fi
	tar -c --files-from $afiles -f - | tar xfC - $INSTALL_TARGET
    else
	tar -cz --files-from $afiles -f oscar-base-$OSCAR_VERSION.tar.gz
    fi
fi

if [ -n "$BUILD_SRPMS" ]; then
    if [ -z "$INSTALL_TARGET" ]; then
	message ">> Building OSCAR SRPMS tarball in "`pwd`
    else
	message ">> Installing OSCAR SRPMS into $INSTALL_TARGET"
    fi

    # build filelist for srpms
    srpms=`get_tfile`
    find $distbase -type d -a -name SRPMS > $srpms
    if [ -n "$INSTALL_TARGET" ]; then
	if [ ! -d "$INSTALL_TARGET" ]; then
	    echo "Target directory $INSTALL_TARGET does not exist."
	    echo "Trying to create it..."
	    mkdir -p $TARGET_DIR || bail_out 1
	fi
	tar -c --files-from $srpms -f - | tar xfC - $INSTALL_TARGET
    else
	tar -cz --files-from $srpms -f oscar-srpms-$OSCAR_VERSION.tar.gz
    fi
fi

rm -rf $distbase

#
# All done
#

cat <<EOF

============================================================================== 
OSCAR version $OSCAR_VERSION distribution created
Documentation: $BUILD_DOCS
Base         : $BUILD_BASE
Install tgt  : $INSTALL_TARGET
SRPMS        : $BUILD_SRPMS
Distros      : $DISTROS
Repo tgt     : $REPO_TARGET
 
Started: $start
Ended:   `date`
============================================================================== 
 
EOF

cleanup
exit 0
