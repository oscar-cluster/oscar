# -*- makefile -*-
#
# Copyright (c) 2004, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: Makefile.am,v 1.12 2004/04/06 14:33:16 brechin Exp $
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
			src \
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
# Print a nice message when the install is done
#

install-exec-hook:
	@echo "------------------------------------------------------------"
	@echo ""
	@echo "OSCAR has been successfully installed to $(prefix)."
	@echo ""
	@echo "You should change to that directory and start the OSCAR"
	@echo "installation process:"
	@echo ""
	@echo "    shell# cd $(prefix)"
	@echo "    shell# ./install_cluster <network_device>"
	@echo ""
	@echo "Consult the OSCAR installation guide for more information."
	@echo ""
	@echo "------------------------------------------------------------"


#
# For making OSCAR distributions
#

oscar-dist:
	$(MAKE) WANT_SRPMS=including dist

#$(MAKE) dist WANT_CORE_ONLY=yes
#mv oscar-$(OSCAR_VERSION).tar.gz \
#	oscar-core-$(OSCAR_VERSION).tar.gz
#$(MAKE) dist WANT_SRPMS=only
#mv oscar-$(OSCAR_VERSION).tar.gz \
#	oscar-only-srpms-$(OSCAR_VERSION).tar.gz
#$(MAKE) dist WANT_SRPMS=including
#mv oscar-$(OSCAR_VERSION).tar.gz \
#	oscar-including-srpms-$(OSCAR_VERSION).tar.gz
#$(MAKE) dist WANT_SRPMS=

dist-nodocs:
	$(MAKE) dist OSCAR_SKIP_DOCS=yes

dist-hook:
	sh ./dist/make-dist.sh "$(DESTDIR)$(distdir)" "$(WANT_SRPMS)" "$(OSCAR_VERSION)" "$(OSCAR_SVN_R)" "$(WANT_CORE_ONLY)" "$(SPLIT_DISTRO)"
