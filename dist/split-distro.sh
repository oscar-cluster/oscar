#!/bin/bash
#
# Copyright (c) Erich Focht 2006 <efocht@hpce.nec.com>

srcdir="`pwd`"
distdir="$srcdir/$1"
OSCAR_VERSION="$2"
FLAVOR="$3"

if [ -n "$FLAVOR" ]; then
    ONAME="oscar-$FLAVOR"
else
    ONAME="oscar"
fi


get_distro_dirs () {
    local dir=`pwd`
    local ddirs
    cd $srcdir/packages/sis/distro
    for d in `/bin/ls -1`; do
	if [ "$d" = "." -o "$d" = ".." -o ! -d "$d" \
	    -o "$d" = "common-rpms" -o "$d" = "common-debs" ]; then
	    continue
	fi
	ddirs="$ddirs $d"
    done
    cd $dir
    echo $ddirs
}

#---


# cd $distdir
# # delete all Makefile* files in the tree
# find . -name 'Makefile*' | xargs rm -f
    
cd $srcdir

supported_mask="fc|rhel|suse|debian|mdv|mdk"

distbase=`basename $distdir`

# build filelist of all files
allfiles=`mktemp`
find $distbase -type f > $allfiles

# build filelist for common files without srpms and distro-specifics
commons=`mktemp`
egrep -v "(packages|share/prereqs)/.*/SRPMS/" $allfiles | \
  egrep -v "(packages|share/prereqs)/.*/distro/($supported_mask)" \
  > $commons
tar -czv --files-from $commons -f $ONAME-common-${OSCAR_VERSION}.tar.bz2
rm -f $commons

# build filelist for srpms
srpmfiles=`mktemp`
egrep "(packages|share/prereqs)/.*/SRPMS/" $allfiles >$srpmfiles
tar -czv --files-from $srpmfiles -f $ONAME-srpms-${OSCAR_VERSION}.tar.bz2
rm -f $srpmfiles

distfiles=`mktemp`
for d in `get_distro_dirs`; do
    # make sure we have no blanks before/after the name
    d=`echo $d | sed -e 's/\ //g'`
    [ -z "$d" ] && continue
    egrep "(packages|share/prereqs)/.*/distro/$d" $allfiles >$distfiles
    NFILES=`cat $distfiles | wc -l`
    if [ $NFILES -eq 0 ]; then
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	echo "distro-arch $d has no files!"
	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	continue
    fi
    echo "================================================="
    echo "  distro-arch: $d  ($NFILES files)"
    echo tar -czv --files-from $distfiles -f $ONAME-$d-${OSCAR_VERSION}.tar.bz2
    echo "================================================="
    tar -czv --files-from $distfiles -f $ONAME-$d-${OSCAR_VERSION}.tar.bz2
done
rm -f $distfiles $allfiles
