# -*- makefile -*-
#
# $Id: Makefile.am,v 1.3 2001/12/22 01:08:36 jsquyres Exp $
#
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
#

AUTOMAKE_OPTIONS	= foreign

SUBDIRS			= \
			dist \
			doc \
			lib \
			images \
			oscarsamples \
			packages \
			scripts \
			testing

noinst_SCRIPTS		= install_cluster

EXTRA_DIST		= README README.ia64 $(noinst_SCRIPTS)

#
# Make the documentation
#

docs:
	(cd doc; $(MAKE) docs)


#
# For making OSCAR distributions
#

dist-hook:
	sh ./dist/make-dist.sh $(DESTDIR)$(distdir)
