#!/bin/sh
#
# $COPYRIGHT$
#
# $Id: get-oscar-version.sh,v 1.1 2001/08/20 23:08:07 jsquyres Exp $
#
# Since we do this in multiple places, it's worth putting in a
# separate shell script.  Very primitive script to get the version
# number of OSCAR into a coherent variable.  Can query for any of the
# individual parts of the version number, too.
#

srcdir="$1"
option="$2"

if test "$srcdir" = ""; then
    option="--help"
else
    OSCAR_MAJOR_VERSION="`cat $srcdir/dist/VERSION | grep major | cut -d= -f2`"
    OSCAR_MINOR_VERSION="`cat $srcdir/dist/VERSION | grep minor | cut -d= -f2`"
    OSCAR_RELEASE_VERSION="`cat $srcdir/dist/VERSION | grep release | cut -d= -f2`"
    OSCAR_ALPHA_VERSION="`cat $srcdir/dist/VERSION | grep alpha | cut -d= -f2`"
    OSCAR_BETA_VERSION="`cat $srcdir/dist/VERSION | grep beta | cut -d= -f2`"
    OSCAR_SVN_VERSION="`cat $srcdir/dist/VERSION | grep svn | cut -d= -f2`"
    if test "$OSCAR_RELEASE_VERSION" != "0" -a "$OSCAR_RELEASE_VERSION" != ""; then
        OSCAR_VERSION="$OSCAR_MAJOR_VERSION.$OSCAR_MINOR_VERSION.$OSCAR_RELEASE_VERSION"
    else
        OSCAR_VERSION="$OSCAR_MAJOR_VERSION.$OSCAR_MINOR_VERSION"
    fi

    if test "`expr $OSCAR_ALPHA_VERSION \> 0`" = "1"; then
        OSCAR_VERSION="${OSCAR_VERSION}a$OSCAR_ALPHA_VERSION"
    elif test "`expr $OSCAR_BETA_VERSION \> 0`" = "1"; then
        OSCAR_VERSION="${OSCAR_VERSION}b$OSCAR_BETA_VERSION"
    fi

    if test "$OSCAR_SVN_VERSION" = "1"; then
        if test -d .svn; then
            ver="r`svnversion .`"
        elif test -f "$srcdir/VERSION.svn"; then
            ver="`cat $srcdir/VERSION.svn`"
        else
            ver="svn`date '+%m%d%Y'`"
        fi
        OSCAR_SVN_VERSION="$ver"
        OSCAR_VERSION="${OSCAR_VERSION}$ver"
    else
        OSCAR_SVN_VERSION=
    fi

    if test "$option" = ""; then
        option="--full"
    fi
fi

case "$option" in
    --full|-v|--version)
        echo $OSCAR_VERSION
	;;
    --major)
        echo $OSCAR_MAJOR_VERSION
	;;
    --minor)
        echo $OSCAR_MINOR_VERSION
	;;
    --release)
        echo $OSCAR_RELEASE_VERSION
	;;
    --alpha)
        echo $OSCAR_ALPHA_VERSION
	;;
    --beta)
        echo $OSCAR_BETA_VERSION
	;;
    --svn)
        echo $OSCAR_SVN_VERSION
	;;
    *)
        cat <<EOF
$0 <srcdir> [<option>]

<srcdir>  - Top-level directory of the OSCAR source tree
<option>  - One of:
    --full    - Full version number
    --major   - Major version number
    --minor   - Minor version number
    --release - Release version number
    --alpha   - Alpha version number
    --beta    - Beta version nmumber
    --svn     - SVN revision number
    --help    - This message
EOF
        ;;
esac

exit 0
