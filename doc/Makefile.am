# -*- makefile -*-
#
# $Id: Makefile.am,v 1.3 2001/12/22 01:08:36 jsquyres Exp $
#
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
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
