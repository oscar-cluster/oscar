# -*- makefile -*-
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: Makefile.am,v 1.9 2003/07/04 14:46:27 jsquyres Exp $
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

include $(top_srcdir)/dist/Makefile.options

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

oscar_SCRIPTS		= install_cluster
oscar_DATA		= COPYING README VERSION

EXTRA_DIST		= $(oscar_SCRIPTS) $(oscar_DATA)

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
