# -*- makefile -*-
#
# $Id: Makefile.am,v 1.1 2001/08/20 23:08:08 jsquyres Exp $
#
# $COPYRIGHT$
#

AUTOMAKE_OPTIONS	= no-dependencies

#
# Set BINARY_FILES to be the list of URLs of binary files to obtain
#

lam_prefix		= http://oscar.sourceforge.net/pub/packages/lam
lam_version		= 6.5.4
BINARY_FILES		= \
	$(lam_prefix)/lam-$(lam_version)-usysv.1oscar.i686.rpm \
	$(lam_prefix)/lam-$(lam_version)-usysv.1oscar.src.rpm

#
# This does the magic to actually download the files if you don't
# already have them
#

include $(top_srcdir)/dist/Makefile.download
