# -*- Makefile -*-
#
# $Id: Makefile,v 1.2 2001/12/17 03:32:16 mchasal Exp $
#
# $COPYRIGHT$
#

LATEX		= latex
PDFLATEX	= pdflatex
FIG2DEV		= fig2dev
DVIPS		= dvips
EPS2PDF		= epstopdf
PNGTOPNM	= pngtopnm
PNMTOPS		= pnmtops -noturn

# The top-level file.

MAIN_TEX	= install.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		titlepage.tex \
		toc.tex \
		intro.tex \
		brief.tex \
		sis.tex \
		outline.tex \
		detailed.tex \
		netboot.tex \
		ramdisk.tex \
		client-install.tex \
		troubleshooting.tex \
		security.tex \
		screen-by-screen.tex

# .eps and .pdf figure files are required to be pre-generated

EPS_FIG_FILES	= \
		oscar-wizard.eps \
		define-server.eps \
		collect-mac.eps \
		define-clients.eps \
		define-disk.eps \
		define-ramdisk.eps \
		allocate-resource.eps \
		per-client.eps \

# SBS (Screen-by-Screen) figures

SBS_FIG_FILES	= \
		sbs-cluster-setup.png \
		sbs-completed.png \
		sbs-define-clients.png \
		sbs-define-clients-res.png \
		sbs-define-clients-start.png \
		sbs-define-server.png \
		sbs-define-server-res.png \
		sbs-etherboot.png \
		sbs-getting-oscar.png \
		sbs-install-oscar2.png \
		sbs-install-oscar.png \
		sbs-install-wizard.png \
		sbs-install-wizard-s1.png \
		sbs-install-wizard-s2.png \
		sbs-install-wizard-s3.png \
		sbs-install-wizard-s6.png \
		sbs-install-wizard-s7.png \
		sbs-mac-boot1-node.png \
		sbs-mac-boot1.png \
		sbs-mac-boot2-node.png \
		sbs-mac-boot2.png \
		sbs-mac-info.png \
		sbs-mac.png \
		sbs-mac-res1.png \
		sbs-mac-res2.png \
		sbs-node1-boot.png \
		sbs-node1-install.png \
		sbs-node1-login.png \
		sbs-node2-boot.png \
		sbs-node2-install.png \
		sbs-pre-client-install.png \
		sbs-pre-client-install-res2.png \
		sbs-pre-client-install-res.png \
		sbs-unpacking-oscar.png

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

SUFFIXES	= .tex .dvi .ps .pdf .eps .png
.SUFFIXES:        .tex .dvi .ps .pdf .eps .png

MAIN_DVI	= $(MAIN_TEX:.tex=.dvi)
MAIN_PS		= $(MAIN_TEX:.tex=.ps)
MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)

EPS_SBS_FIG_FILES = $(SBS_FIG_FILES:.png=.eps)
PDF_FIG_FILES	= $(EPS_FIG_FILES:.eps=.pdf)

# Some common target names

docs: $(MAIN_PS)

ps: $(EPS_FIG_FILES) $(MAIN_PS)
pdf: $(PDF_FIG_FILES) $(MAIN_PDF)

#
# Make the dependencies so that things build when they need to
#

$(MAIN_PS): $(MAIN_DVI)
$(MAIN_DVI): $(MAIN_TEX) $(OTHER_SRC_FILES) $(EPS_FIG_FILES) $(EPS_SBS_FIG_FILES)
$(MAIN_PDF): $(MAIN_TEX) $(OTHER_SRC_FILES) $(PDF_FIG_FILES) $(SBS_FIG_FILES)

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
	$(PNGTOPNM) $< | $(PNMTOPS) > $*.eps

# Deleting kruft temporary files

clean: mostlyclean
	-rm -f $(MAIN_PS) $(MAIN_DVI) $(MAIN_PDF)

mostlyclean:
	-rm -f *~ *.bak *% \
		*.log *.aux *.dvi *.blg *.toc *.bbl *.lof *.lot *.out \
		$(EPS_SBS_FIG_FILES)

