# -*- Makefile -*-
#
# $Id: Makefile.am,v 1.9 2002/06/21 08:38:29 naughtont Exp $
# 
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
#

# The top-level file.

MAIN_TEX	= install.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		titlepage.tex \
		toc.tex \
		intro.tex \
		release-notes.tex \
		brief.tex \
		sis.tex \
		outline.tex \
		detailed.tex \
		notes.tex \
		netboot.tex \
		client-install.tex \
		troubleshooting.tex \
		security.tex \
		screen-by-screen.tex

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
		sbs-addclients1.png \
		sbs-addclients2.png \
		sbs-build-image1.png \
		sbs-build-image2.png \
		sbs-client-rsync.png \
		sbs-collect-mac1.png \
		sbs-collect-mac2.png \
		sbs-collect-mac3.png \
		sbs-collect-mac4.png \
		sbs-install-oscar2.png \
		sbs-install-oscar.png \
		sbs-wizard-step1.png \
		sbs-wizard-step2.png \
		sbs-wizard-step3.png \
		sbs-wizard-step4.png \
		sbs-wizard-step5.png \
		sbs-test1.png \
		sbs-test2.png \
		sbs-download.png \
		sbs-unpack.png \
		sbs-client-boot.png \
		sbs-client-broadcast.png \
		sbs-client-answer.png \
		sbs-client-diskpar.png \
		sbs-client-finished.png \
		sbs-post-install.png \
		figs/0a_sbs-download.png \
		figs/0b_sbs-rh72notes-rpm-upgrd.png \
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
		figs/6c_sbs-client-boot1.png \
		figs/6c_sbs-client-boot22.png \
		figs/6d_sbs-broadcast.png \
		figs/6e_sbs-found-mac.png \
		figs/6g_sbs-assign-mac.png \
		figs/6h_sbs-client-boot.png \
		figs/6i_sbs-client-diskpar.png \
		figs/6j_sbs-client-rsync.png \
		figs/6k_sbs-rebootme.png \
		figs/9a_sbs-add-node.png 



#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

SUFFIXES	= .tex .dvi .ps .pdf .eps .png

MAIN_DVI	= $(MAIN_TEX:.tex=.dvi)
MAIN_PS		= $(MAIN_TEX:.tex=.ps)
MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)

TEX_SRC		= $(MAIN_TEX) $(OTHER_SRC_FILES) $(NON_DIST_SRC_FILES)

EPS_FIG_FILES	= $(FIG_FILES:.png=.eps) $(SBS_FILES:.png=.eps)

# Tell automake to include all the relevant files

EXTRA_DIST	= $(MAIN_TEX) $(OTHER_SRC_FILES) $(FIG_FILES) $(SBS_FILES)
CLEANFILES	= $(MAIN_PS) $(MAIN_DVI) $(MAIN_PDF) *~ notes.tex

# Some common target names

all: ps
docs: $(MAIN_PS)

ps: $(EPS_FIG_FILES) $(MAIN_PS)
pdf: $(PNG_FIG_FILES) $(MAIN_PDF)

#
# Make the dependencies so that things build when they need to
#

$(MAIN_PS): $(MAIN_DVI)
$(MAIN_DVI): $(TEX_SRC) $(EPS_FIG_FILES)
$(MAIN_PDF): $(TEX_SRC) $(FIG_FILES) $(SBS_FILES)

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
