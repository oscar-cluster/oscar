#! /bin/sh 
#
# Copyright (c) 2004, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id: autogen.sh,v 1.17 2004/04/05 21:39:47 brechin Exp $
#

#
# Some globals
#

sentinel_file=.oscar_made_makefile_am
ac_config_files_output=dist/config_files_list.m4
ignore_file=.oscar_ignore

#
# Some helper functions
#

test_for_existence() {
    tfe_prog="$1"
    tfe_foo="`$tfe_prog --version`"
    if test "$?" != 0; then
	cat <<EOF

You must have GNU autoconf and automake are installed to build the
developer's version of OSCAR.  You can obtain these packages from
ftp://ftp.gnu.org/gnu/.

EOF
	# Stupid emacs: '
	exit 1
    fi
    unset tfe_prog tfe_foo
}

run_and_check() {
    rac_progs="$*"
    echo "$rac_progs"
    eval $rac_progs
    if test "$?" != 0; then
	cat <<EOF

It seems that the execution of "$progs" has failed.
I am gonna abort.  :-(

This may be caused by an older version of one of the required
packages.  Please make sure you are using at least the following
versions:

GNU Autoconf 2.52
GNU Automake 1.5

EOF
	exit 1
    fi
    unset rac_progs
}

#
# Subroutine to look for standard files in a number of common places
# (e.g., ./config.guess, config/config.guess, dist/config.guess), and
# delete it.  If it's not found there, look for AC_CONFIG_AUX_DIR in
# the configure.in script and try there.  If it's not there, oh well.
#
find_and_delete() {
    fad_file="$1"

    # Look for the file in "standard" places

    if test -f $fad_file; then
	rm -f $fad_file
    elif test -d config/$fad_file; then
	rm -f config/$fad_file
    elif test -d dist/$fad_file; then
	rm -f dist/$fad_file
    else

	# Didn't find it -- look for an AC_CONFIG_AUX_DIR line in
	# configure.[in|ac]

	if test -f configure.in; then
	    fad_cfile=configure.in
	elif test -f configure.ac; then
	    fad_cfile=configure.ac
	fi
	auxdir="`grep AC_CONFIG_AUX_DIR $fad_cfile | cut -d\( -f 2 | cut -d\) -f 1`"
	if test -f "$auxdir/$fad_file"; then
	    rm -f "$auxdir/$fad_file"
	fi
	unset fad_cfile
    fi
    unset fad_file
}


#
# Subroutine to actually do the GNU tool setup in the proper order, etc.
#
run_gnu_tools() {
    rgt_dir="$1"
    rgt_cur_dir="`pwd`"
    if test -d "$rgt_dir"; then
	cd "$rgt_dir"

        # Find and delete the GNU helper script files

	find_and_delete config.guess
	find_and_delete config.sub
	find_and_delete depcomp
	find_and_delete install-sh
	find_and_delete missing
	find_and_delete mkinstalldirs

        # Run the GNU tools

	run_and_check aclocal
	run_and_check autoconf
	run_and_check automake -a --copy
	
        # Go back to the original directory

	cd "$rgt_cur_dir"
    fi
    unset rgt_dir rgt_cur_dir
}

#
# Subroutine to make a Makefile.am in given directory
#
make_makefile() {
    mm_dir="$1"
    mm_curdir="`pwd`"
    mm_outfile="$mm_dir/Makefile.am"

    # Make the Makefile.am in a given directory.  The primary contents
    # of this file will be the EXTRA_DIST variable and the SUBDIRS
    # variable.  For these simplistic templates, we take all files and
    # subdirectories (except those named ".svn").  If package authors
    # want anything more interesting, they can supply their own
    # Makefile.am's.

    mm_extra_data=
    mm_extra_scripts=
    mm_subdirs=
    
    touch $mm_dir/$sentinel_file

    \rm -f $mm_outfile
    echo " - $mm_outfile"
    cat > $mm_outfile <<EOF
# -*- makefile -*-
#
# Copyright (c) 2004, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
#
#   This file is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This file is part of the OSCAR software package.
#
# This file was automatically generated by the OSCAR autogen.sh script.
#
################################################
# DO NOT EDIT MANUALLY; CHANGES WILL BE LOST!! #
################################################
#

include \$(top_srcdir)/dist/Makefile.options

EOF

    # Go through all the entries in this directory.  If it's a
    # directory and not a "bad" one, add it to the subdirs list.  If
    # it's a file, and not a "bad" one, then add it to the extra_dist
    # list.

    cd "$mm_dir"
    for mm_file in *; do
	if test -d "$mm_file" \
	    -a ! -f "$mm_file/.oscar_ignore" \
	    -a "$mm_file" != "." \
	    -a "$mm_file" != ".." \
	    -a "$mm_file" != "autom4te.cache" \
	    -a "$mm_file" != ".svn"; then
	    mm_subdirs="$mm_file $mm_subdirs"
	elif test -f "$mm_file"; then
	    if test "$mm_file" != ".cvsignore" \
		-a "$mm_file" != "Makefile.am" \
		-a "$mm_file" != "Makefile.in" \
		-a "$mm_file" != "Makefile" \
		-a "`echo $mm_file | egrep '~$'`" == "" \
		-a "`echo $mm_file | egrep '\.bak$'`" == "" \
		; then
		if test -x "$mm_file"; then
		    mm_extra_scripts="$mm_file $mm_extra_scripts"
		else
		    mm_extra_data="$mm_file $mm_extra_data"
		fi
	    fi
	fi
    done
    cd "$mm_curdir"

    # Add the results to the new Makefile.am file.

    if test -n "$mm_subdirs"; then
	echo "SUBDIRS = $mm_subdirs" >> $mm_outfile
    fi
    extra_dist=0
    if test -n "$mm_extra_scripts" -o -n $"mm_extra_data"; then
	cat >> $mm_outfile <<EOF
oscar_SCRIPTS = $mm_extra_scripts
oscar_DATA = $mm_extra_data
EXTRA_DIST = \$(oscar_SCRIPTS) \$(oscar_DATA)
EOF
    fi

    unset mm_dir mm_curdir mm_outfile mm_extra_dirs mm_subdirs
}

#
# Subroutine to traverse a tree in make Makefile.am's in all
# subdirectories.
#
traverse_tree() {
    topdir="$1"

    # Make the Makefile.am in this directory

    make_makefile "$topdir"

    # Now recursivelytraverse children subdirs

    for file in "$topdir"/*; do
	if test "$file" != "$topdir/.svn" -a \
	    "$file" != "." -a \
	    "$file" != ".." -a \
	    -d "$file" -a \
	    ! -f "$file/$ignore_file" -a \
	    \( ! -f "$file/Makefile.am" -o -f "$file/$sentinel_file" \); then
	    traverse_tree "$file"
	fi
    done
}

#
# Subroutine to run across the entire OSCAR tree
#
run_global() {
    # Write src Makefile source
    # Blatant and probably poor redux of the code below
    echo "Generating src/Makefile.am..."
    base="`basename src`"
    if 	[ -d "src" -a \
	"$base" != "." -a \
	"$base" != ".." -a \
	 ! -f "src/$ignore_file" ]; then
	for subdir in src; do
	  if [ -d $subdir -a \
	     ! -f $subdir/$ignore_file -a \
	     "$subdir" != "src/.svn" ]; then
		make_makefile "src"
          fi
	done
    fi

    # Now examine all the package/*/{set} directories (where {set} is
    # a pre-defined set of expected directories in each OSCAR
    # package).  If they don't already have a Makefile.am, make one,
    # and add it to the various lists of directories.

    echo "Generating Makefile.am's..."
    rg_pkg_subdirs=". distro doc RPMS scripts SRPMS testing"
    for rg_pkg in packages packages/*; do
	rg_base="`basename $rg_pkg`"
	if test "$rg_pkg" != "packages/.svn" -a \
	    -d "$rg_pkg" -a \
	    "$rg_base" != "." -a \
	    "$rg_base" != ".." -a \
	    ! -f "$rg_pkg/$ignore_file"; then
	    for rg_subdir in $rg_pkg_subdirs; do
		if test -d "$rg_pkg/$rg_subdir" -a \
		    ! -f "$rg_pkg/$rg_subdir/$ignore_file"; then
		    if test ! -f "$rg_pkg/$rg_subdir/Makefile.am" -o \
			-f "$rg_pkg/$rg_subdir/$sentinel_file"; then
			if test "`basename $rg_subdir`" != "."; then
			    traverse_tree "$rg_pkg/$rg_subdir"
			else
			    make_makefile "$rg_pkg"
			fi
		    fi
		fi
	    done
	fi
    done

    # With all that done, make up the list of Makefile's that
    # configure has to generate in AC_OUTPUT.

    echo "Generating AC_CONFIG_FILES list..."

    \rm -f $ac_config_files_output
    cat > $ac_config_files_output <<EOF
# -*- m4 -*-
#
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
#
# This file was automatically generated by the OSCAR autogen.sh script.
#

AC_CONFIG_FILES([
EOF

    rg_config_files=
    for rg_dir in `find packages -type d`; do
	base="`basename $rg_dir`"
	if test "$base" != ".svn" -a \
	    ! -f "$rg_dir/$ignore_file" -a \
	    -f "$rg_dir/$sentinel_file" -a \
	    -f "$rg_dir/Makefile.am" ; then
            echo "    $rg_dir/Makefile" >> $ac_config_files_output
	fi
    done
    cat >> $ac_config_files_output <<EOF
])
EOF

    unset rg_pkg rg_subdir rg_pkg_subdirs rg_config_files rg_ddir
}

##########################################################################
# Main
##########################################################################

# Are we in the right directory?  We must be in the top-level OSCAR
# directory.

if test -f dist/VERSION -a -f configure.in -a -f lib/OSCAR/PackageBest.pm; then
    bad=0
else
    cat <<EOF

You must run this script from the top-level OSCAR directory.

EOF
    exit 1
fi

test_for_existence autoconf
test_for_existence automake

# Now do the run

run_global
run_gnu_tools .

# All done

exit 0
