# -*- makefile -*-
#
# $Id: Makefile.am,v 1.2 2001/12/19 02:36:54 jsquyres Exp $
#
# $COPYRIGHT$
#

SUBDIRS			= architecture development installation introduction

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
