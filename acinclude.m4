#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: acinclude.m4,v 1.2 2003/07/04 14:01:01 jsquyres Exp $
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

AC_DEFUN([OSCAR_CHECK_PROG], [
#
# Wrapper around AC_CHECK_PROG.  Put in some additional functionality:
#
# - call AC_MSG_ERROR if don't find target program (i.e., abort)
#
# $1 = variable to store result in
# $2 = program to look for
# $3 = whether we should abort if we can't find it
#
AC_CHECK_PROG($1, $2, $2, no)
if test "$$1" = "no"; then
    AC_MSG_WARN([*** Couldn't find program "$2"])
    if test "$3" = "yes"; then
	AC_MSG_WARN([*** $2 is necessary to build an OSCAR distribution package])
	AC_MSG_ERROR([*** Cannot continue.])
    fi
    found_oscar_progs=no
fi

AC_ARG_VAR([$1], [$2 program location])
])dnl
