# -*- makefile -*-
#
# $Id: Makefile.am,v 1.8 2002/10/26 12:08:36 jsquyres Exp $
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
			share \
			testing

noinst_SCRIPTS		= install_cluster

EXTRA_DIST		= COPYING README $(noinst_SCRIPTS) VERSION

#
# Make the documentation
#

docs:
	(cd doc; $(MAKE) docs)


#
# For making OSCAR distributions
#

oscar-dist:
	$(MAKE) dist WANT_SRPMS=only
	mv oscar-$(OSCAR_VERSION).tar.gz \
		oscar-only-srpms-$(OSCAR_VERSION).tar.gz
	$(MAKE) dist WANT_SRPMS=including
	mv oscar-$(OSCAR_VERSION).tar.gz \
		oscar-including-srpms-$(OSCAR_VERSION).tar.gz
	$(MAKE) dist WANT_SRPMS=

dist-nodocs:
	$(MAKE) dist OSCAR_SKIP_DOCS=yes

dist-hook:
	sh ./dist/make-dist.sh $(DESTDIR)$(distdir) $(WANT_SRPMS)
