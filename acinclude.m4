#
# $Id: acinclude.m4,v 1.1 2002/07/24 03:27:38 jsquyres Exp $
#
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
#

AC_DEFUN([OSCAR_CHECK_PROG], [
#
# Wrapper around AC_CHECK_PROG.  Put in some additional functionality:
#
# - call AC_MSG_ERROR if don't find target program (i.e., abort)
#
# $1 = variable to store result in
# $2 = program to look for
#
AC_CHECK_PROG($1, $2, $2, no)
if test "$$1" = "no"; then
    AC_MSG_WARN([*** Couldn't find program "$2" -- "$2" is necessary])
    AC_MSG_WARN([*** to build an OSCAR distribution package.])
    AC_MSG_ERROR([*** Cannot continue.])
fi
AC_ARG_VAR([$1], [$2 program location])
])dnl
