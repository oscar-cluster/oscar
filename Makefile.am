# -*- makefile -*-
#
# $Id: Makefile.am,v 1.1 2001/08/20 23:08:07 jsquyres Exp $
#
# $COPYRIGHT$
#

AUTOMAKE_OPTIONS	= foreign no-dependencies

#SUBDIRS			= core-packages packages doc
SUBDIRS			= packages doc
EXTRA_DIST		= README

#
# Make the documentation
#

docs:
	(cd doc; $(MAKE) docs)


#
# For making OSCAR distributions
#

dist-hook:
	sh ./dist/make-dist.sh
