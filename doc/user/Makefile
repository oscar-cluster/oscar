# -*- Makefile -*-
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: Makefile,v 1.2 2003/07/29 19:50:19 jsquyres Exp $
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

# The top-level file.

MAIN_TEX	= user.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		titlepage.tex \
		toc.tex \
		intro.tex \
		package-docs.tex \
		package-license.tex

NON_DIST_SRC_FILES= \
		version.tex

# .eps and .pdf figure files are required to be pre-generated

FIG_FILES	=

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

# Meta-.tex file to include the doc/user.tex files from the various
# package directories.  This covers a few more dependencies than it
# really should, but better safe than sorry...

ifndef top_srcdir
# Assume that this is not a VPATH build.  I refuse to be an enabler
# for someone trying to do a VPATH build of maintainer-only docs.  :-)
	top_srcdir=../..
	top_builddir=../..
endif

version.tex: $(top_srcdir)/dist/VERSION
	rm -f version.tex
	ver="`$(top_srcdir)/dist/get-oscar-version.sh $(top_srcdir)`"; \
		sed -e s/@OSCAR_VERSION@/$$ver/ version.tex.in > version.tex

package-docs.tex: package-docs.tex.in $(top_srcdir)/packages/*/doc/*.tex
	$(top_srcdir)/doc/user/build-package-docs

package-license.tex: package-docs.tex.in $(top_srcdir)/packages/*/doc/*.tex
	$(top_srcdir)/doc/user/build-package-license

EXTRA_DISTFILES	= build-package-docs build-package-license
EXTRA_CLEANFILES= package-docs.tex package-license.tex version.tex

# All the logic to build documents.
# Using a GNU make extension for this (clearly I'm heading for hell
# when I die).

include $(top_srcdir)/doc/Makefile.latex
