# -*- Makefile -*-
#
# $Id: Makefile.am,v 1.15 2002/08/31 22:36:18 jsquyres Exp $
# 
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
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
		brief.tex \
		sis.tex \
		outline.tex \
		detailed.tex \
		notes.tex \
		netboot.tex \
		client-install.tex \
		security.tex \
		screen-by-screen.tex

QUICK_SRC_FILES= \
		quick_titlepage.tex \
		download.tex \
		brief.tex \
		supported.tex

NON_DIST_SRC_FILES= \
		version.tex

# .eps and .pdf figure files are required to be pre-generated

FIG_FILES	= \
		oscar-wizard.png \
		collect-mac.png \
		define-clients.png \
		build-image.png \
		setup-test.png

# SBS (Screen-by-Screen) figures

SBS_FILES	= \
			 figs/0a_sbs-download.png \
			 figs/0c_sbs-unpack.png \
			 figs/10a_sbs-del-node.png \
			 figs/10b_sbs-del-node-partA.png \
			 figs/10b_sbs-del-node-partB.png \
			 figs/1a_sbs-install-oscar.png \
			 figs/1b_sbs-install-oscar2.png \
			 figs/2_sbs-oscar-wizard.png \
			 figs/3a_sbs-wizard-step1.png \
			 figs/3b_sbs-wizard-step1.png \
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
			 figs/8_sbs-test-cluster-prompt.png \
			 figs/8_sbs-test-cluster-root-tests.png \
			 figs/8_sbs-test-cluster-user-tests.png \
			 figs/8_test-cluster-complete.png \
			 figs/9a_sbs-add-node.png \
			 figs/9b_sbs-add-node-mksirange.png \
			 figs/9c_sbs-add-node-success.png \
			 figs/9d_sbs-add-node-mac1.png \
			 figs/9e_sbs-add-node-mac2.png \
			 figs/9f_sbs-add-node-complete.png 




#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

SUFFIXES	= .tex .dvi .ps .pdf .eps .png

MAIN_DVI	= $(MAIN_TEX:.tex=.dvi)
MAIN_PS		= $(MAIN_TEX:.tex=.ps)
MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)

QUICK_DVI	= $(QUICK_TEX:.tex=.dvi)
QUICK_PS	= $(QUICK_TEX:.tex=.ps)
QUICK_PDF	= $(QUICK_TEX:.tex=.pdf)

TEX_SRC		= $(MAIN_TEX) $(OTHER_SRC_FILES) $(NON_DIST_SRC_FILES)
QUICK_SRC	= $(QUICK_TEX) $(QUICK_SRC_FILES) $(NON_DIST_SRC_FILES)

EPS_FIG_FILES	= $(FIG_FILES:.png=.eps) $(SBS_FILES:.png=.eps)

# Tell automake to include all the relevant files

EXTRA_DIST	= $(MAIN_TEX) $(OTHER_SRC_FILES) $(FIG_FILES) $(SBS_FILES) \
		  $(QUICK_TEX) $(QUICK_SRC_FILES)
CLEANFILES	= $(MAIN_PS) $(MAIN_DVI) $(MAIN_PDF) *~ notes.tex \
		  $(QUICK_PS) $(QUICK_DVI) $(QUICK_PDF)

# Some common target names

all: ps
docs: $(MAIN_PS) $(QUICK_PS)

ps: $(EPS_FIG_FILES) $(MAIN_PS) $(QUICK_PS)
pdf: $(PNG_FIG_FILES) $(MAIN_PDF) $(QUICK_PDF)

#
# Make the dependencies so that things build when they need to
#

$(MAIN_PS): $(MAIN_DVI)
$(MAIN_DVI): $(TEX_SRC) $(EPS_FIG_FILES)
$(MAIN_PDF): $(TEX_SRC) $(FIG_FILES) $(SBS_FILES)

$(QUICK_PS): $(QUICK_DVI)
$(QUICK_DVI): $(QUICK_SRC)
$(QUICK_PDF): $(QUICK_SRC)

#
# General rules
#

.tex.dvi:
	(unset TEXINPUTS; $(LATEX) $*)
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null ); \
	then (unset TEXINPUTS; $(LATEX) $*) ; else :; fi
	@ if ( grep 'Writing index file' $*.log > /dev/null ); \
	then makeindex $* ; (unset TEXINPUTS; $(LATEX) $*) ; fi
	@-if ( grep 'LaTeX Warning: Citation' $*.log > /dev/null ); then \
	  bibtex $* ; \
	  (unset TEXINPUTS; $(LATEX) $*) ; \
	fi
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null || \
	      grep 'LaTeX Warning: Citation' $*.log > /dev/null || \
	      grep 'No file' $*.log > /dev/null); \
	then (unset TEXINPUTS; $(LATEX) $*) ; else :; fi
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null || \
	      grep 'LaTeX Warning: Citation' $*.log > /dev/null); \
	then (unset TEXINPUTS; $(LATEX) $*) ; else :; fi
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null || \
	      grep 'LaTeX Warning: Citation' $*.log > /dev/null); \
	then (unset TEXINPUTS; $(LATEX) $*) ; else :; fi

.dvi.ps:
	$(DVIPS) -o $*.ps $*

.tex.pdf:
	(unset TEXINPUTS; $(PDFLATEX) $*)
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null ); \
	then (unset TEXINPUTS; $(PDFLATEX) $*) ; else :; fi
	@ if ( grep 'Writing index file' $*.log > /dev/null ); \
	then makeindex $* ; (unset TEXINPUTS; $(PDFLATEX) $*) ; fi
	@-if ( grep 'LaTeX Warning: Citation' $*.log > /dev/null ); then \
	  bibtex $* ; \
	  (unset TEXINPUTS; $(PDFLATEX) $*) ; \
	fi
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null || \
	      grep 'LaTeX Warning: Citation' $*.log > /dev/null || \
	      grep 'No file' $*.log > /dev/null); \
	then (unset TEXINPUTS; $(PDFLATEX) $*) ; else :; fi
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null || \
	      grep 'LaTeX Warning: Citation' $*.log > /dev/null); \
	then (unset TEXINPUTS; $(PDFLATEX) $*) ; else :; fi
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null || \
	      grep 'LaTeX Warning: Citation' $*.log > /dev/null); \
	then (unset TEXINPUTS; $(PDFLATEX) $*) ; else :; fi

.png.eps:
	$(PNGTOPNM) $< | $(PNMTOPS) -noturn > $*.eps

# Deleting kruft temporary files

mostlyclean-generic:
	-rm -f *~ *.bak *% \
		  *.log *.aux *.dvi *.blg *.toc *.bbl *.lof *.lot *.out \
		  $(EPS_FIG_FILES)

# Meta-.tex file to include the doc/user.tex files from the various
# package directories.  This covers a few more dependencies than it
# really should, but better safe than sorry...

notes.tex: notes.tex.in ../../packages/*/doc/*.tex
	./build-notes
