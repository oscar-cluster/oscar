# -*- makefile -*-
#
# $Id: Makefile.am,v 1.2 2001/12/19 02:36:54 jsquyres Exp $
#
# $COPYRIGHT$
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
