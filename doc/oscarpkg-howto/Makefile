# -*- Makefile -*-
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: Makefile,v 1.3 2003/10/01 20:36:37 naughtont Exp $
#
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

# The top-level file.

MAIN_TEX	= oscarpkg-howto.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		env-switcher.tex \
		intro.tex \
		oda.tex \
		opd.tex \
		oscar-envvars-table.tex \
		pkg-example.tex \
		pkg-layout.tex \
		pkg-scripts-table.tex \
		pkg-xml-table.tex \
		configurator.tex 

# xfig figures.  .eps and .pdf files will be automatically generated
# from these.

FIG_FILES	= \
		figs/Comments.png \
		figs/ConfiguratorExample.png \
		figs/EnableRootAccess.png \
		figs/EnterYourName2.png \
		figs/EnterYourName.png \
		figs/EnterYourPassword.png \
		figs/HiddenElement.png \
		figs/ResetForm.png \
		figs/SelectMachine.png \
		figs/UserType.png 


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
