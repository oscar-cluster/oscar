# -*- Makefile -*-
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: Makefile,v 1.3 2003/07/04 14:34:03 jsquyres Exp $
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

# The top-level file.

MAIN_TEX	= architecture.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		titlepage.tex \
		toc.tex \
		intro.tex \
		oscar-1.tex \
		requirements.tex \
		design.tex \
		core-packages.tex \
		included-packages.tex \
		xml.tex

# xfig figures.  .eps and .pdf files will be automatically generated
# from these.

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
