# -*- makefile -*-
#
# $Id: Makefile.am,v 1.2 2001/08/28 00:50:25 jsquyres Exp $
#
# $COPYRIGHT$
#

AUTOMAKE_OPTIONS	= no-dependencies

#
# Set BINARY_FILES to be the list of URLs of binary files to obtain
#

lam_prefix		= http://oscar.sourceforge.net/pub/packages/lam
lam_version		= 6.5.4
DOWNLOAD_FILES		= \
	$(lam_prefix)/lam-$(lam_version)-usysv.1oscar.i686.rpm \
	$(lam_prefix)/lam-$(lam_version)-usysv.1oscar.src.rpm

#
# This does the magic to actually download the files if you don't
# already have them
#

include $(top_srcdir)/dist/Makefile.download
