# -*- makefile -*-
#
# $Id: Makefile.am,v 1.1 2001/08/20 23:08:07 jsquyres Exp $
#
# $COPYRIGHT$
#

AUTOMAKE_OPTIONS	= no-dependencies

SUBDIRS			= architecture development

#
# Make the documentation
#

docs:
	@set fnord $(MAKEFLAGS); amf=$$2; \
	target=`echo $@ | sed s/-recursive//`; \
	list='$(SUBDIRS)'; for subdir in $$list; do \
	  echo "Making $$target in $$subdir"; \
	  (cd $$subdir && $(MAKE) $(AM_MAKEFLAGS) $$target) \
	   || case "$$amf" in *=*) exit 1;; *k*) fail=yes;; *) exit 1;; esac; \
	done; 
