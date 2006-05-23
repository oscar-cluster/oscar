# -*- Makefile -*-
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id$
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

# The top-level file.

MAIN_TEX	= by-laws.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		differences.tex \
		intro.tex \
		titlepage.tex \
		toc.tex

NON_DIST_SRC_FILES=

# .eps and .pdf figure files are required to be pre-generated

FIG_FILES	=

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

# All the logic to build documents.
# Using a GNU make extension for this (clearly I'm heading for hell
# when I die).

ifndef top_srcdir
# Assume that this is not a VPATH build.  I refuse to be an enabler
# for someone trying to do a VPATH build of maintainer-only docs.  :-)
	top_srcdir=../..
	top_builddir=../..
endif
include $(top_srcdir)/doc/Makefile.latex
