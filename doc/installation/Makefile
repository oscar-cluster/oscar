# -*- Makefile -*-
#
# Copyright (c) 2002-2003 The Trustees of Indiana University.  
#                         All rights reserved.
# 
# $Id: Makefile,v 1.12 2003/11/16 03:43:16 bernardli Exp $
# 
# This file is part of the OSCAR distribution.  See license
# information in the top-level directory.
#

# The top-level file.

MAIN_TEX	= install.tex
QUICK_TEX	= quick_install.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		titlepage.tex \
		toc.tex \
		intro.tex \
		download.tex \
		supported.tex \
		release-notes.tex \
		sis.tex \
		detailed.tex \
		notes.tex \
		netboot.tex \
		client-install.tex \
		security.tex \
		screen-by-screen.tex

QUICK_SRC_FILES= \
		detailed.tex \
		download.tex \
		intro.tex \
		quick_titlepage.tex \
		supported.tex \
		toc.tex

NON_DIST_SRC_FILES= \
		version.tex

# .eps and .pdf figure files are required to be pre-generated

FIG_FILES	= \
		oscar-wizard.png \
		collect-mac.png \
		define-clients.png \
		build-image.png \
		setup-test.png \
			 figs/0c_sbs-unpack.png \
			 figs/1a_sbs-install-oscar.png \
			 figs/1b_sbs-install-oscar2.png \
			 figs/10a_sbs-del-node.png \
			 figs/10b_sbs-del-node-partA.png \
			 figs/10b_sbs-del-node-partB.png \
			 figs/install-server-pkgs-done.png \
			 figs/2_sbs-oscar-wizard.png \
			 figs/package-selection.png \
			 figs/package-configuration.png \
			 figs/package-configuration-switcher.png \
			 figs/4a_sbs-build-image1.png \
			 figs/4b_sbs-build-image2.png \
			 figs/4c_sbs-build-image3.png \
			 figs/5a_sbs-define-clients1.png \
			 figs/5b_sbs-define-clients2.png \
			 figs/6a_sbs-collect-mac1.png \
			 figs/6ba_sbs-autoinstall-flpy1.png \
			 figs/6bb_sbs-autoinstall-flpy2.png \
			 figs/6bc_sbs-autoinstall-flpy3.png \
			 figs/6ca_sbs-client-boot1.png \
			 figs/6c_sbs-client-boot1.png \
			 figs/6d_sbs-broadcast.png \
			 figs/6e_sbs-found-mac.png \
			 figs/6f_sbs-stop-collect-mac2.png \
			 figs/6h_sbs-client-boot.png \
			 figs/6i_sbs-client-diskpar.png \
			 figs/6j_sbs-client-rsync.png \
			 figs/6k_sbs-rebootme.png \
			 figs/7_sbs-complete-cluster-setup.png \
			 figs/8_test-cluster-complete.png \
			 figs/9a_sbs-add-node.png \
			 figs/9b_sbs-add-node-mksirange.png \
			 figs/9c_sbs-add-node-success.png \
			 figs/9d_sbs-add-node-mac1.png \
			 figs/9e_sbs-add-node-mac2.png \
			 figs/9f_sbs-add-node-complete.png  \
			 figs/sbs-configure-install.png \
			 figs/sbs-make-install-1.png \
			 figs/sbs-make-install-2.png \
			 figs/sbs-download-packages.png \
			 figs/sbs-opder-alt-repository.png \
			 figs/sbs-pkgInUn-selector.png \
			 figs/sbs-pkgInUn-selector-example-colors.png


#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

QUICK_DVI	= $(QUICK_TEX:.tex=.dvi)
QUICK_PS	= $(QUICK_TEX:.tex=.ps)
QUICK_PDF	= $(QUICK_TEX:.tex=.pdf)
QUICK_HTML	= $(QUICK_TEX:.tex=)/$(QUICK_TEX:.tex=.html)

QUICK_SRC	= $(QUICK_TEX) $(QUICK_SRC_FILES) $(NON_DIST_SRC_FILES)

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

notes.tex: notes.tex.in $(top_srcdir)/packages/*/doc/*.tex
	$(top_srcdir)/doc/installation/build-notes

EXTRA_DISTFILES	= $(QUICK_TEX) $(QUICK_SRC_FILES) build-notes
EXTRA_CLEANFILES= $(QUICK_PS) $(QUICK_DVI) $(QUICK_PDF) notes.tex version.tex
EXTRA_PS	= $(QUICK_PS)
EXTRA_PDF	= $(QUICK_PDF)
EXTRA_HTML	= $(QUICK_HTML)

# All the logic to build documents.
# Using a GNU make extension for this (clearly I'm heading for hell
# when I die).

include $(top_srcdir)/doc/Makefile.latex
