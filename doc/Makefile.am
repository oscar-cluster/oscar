# -*- makefile -*-
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: Makefile.am,v 1.6 2003/07/04 14:27:39 jsquyres Exp $
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

include $(top_srcdir)/dist/Makefile.options

oscar_DATA		= README
EXTRA_DIST		= $(oscar_DATA)

#
# Make the documentation.  Need special handling because these
# directories may (developer tree) or may not (distribution tree) be
# here.
#

docs_subdirs	= architecture by-laws development installation user

docs:
	set fnord $(MAKEFLAGS); amf=$$2; \
	mypwd="`pwd`"; \
	cd "$(top_srcdir)"; mytop_srcdir="`pwd`"; \
	cd "$$mypwd"; \
	cd "$(top_builddir)"; mytop_builddir="`pwd`"; \
	cd "$$mypwd"; \
	list='$(docs_subdirs)'; for subdir in $$list; do \
	  if test -d $$subdir; then \
	    echo "Making $$target in $$subdir"; \
	    (cd $$subdir && \
		$(MAKE) $(AM_MAKEFLAGS) top_srcdir="$$mytop_srcdir" top_builddir="$$mytop_builddir" docs) \
	     || case "$$amf" in *=*) exit 1;; *k*) fail=yes;; *) exit 1;; esac; \
	  fi; \
	done; 

clean-local:
	set fnord $(MAKEFLAGS); amf=$$2; \
	mypwd="`pwd`"; \
	cd "$(top_srcdir)"; mytop_srcdir="`pwd`"; \
	cd "$$mypwd"; \
	cd "$(top_builddir)"; mytop_builddir="`pwd`"; \
	cd "$$mypwd"; \
	list='$(docs_subdirs)'; for subdir in $$list; do \
	  if test -d $$subdir; then \
	    echo "Making $$target in $$subdir"; \
	    (cd $$subdir && \
		$(MAKE) $(AM_MAKEFLAGS) top_srcdir="$$mytop_srcdir" top_builddir="$$mytop_builddir" clean) \
	     || case "$$amf" in *=*) exit 1;; *k*) fail=yes;; *) exit 1;; esac; \
	  fi; \
	done; 
