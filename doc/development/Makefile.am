# -*- Makefile -*-!ls
#
# $Id: Makefile.am,v 1.7 2002/11/16 05:33:13 bligneri Exp $
#
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
#

# The top-level file.

MAIN_TEX	= development.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		cvs.tex \
		core.tex \
		collaboration.tex \
		directories.tex \
		defs.tex \
		intro.tex \
		files.tex \
		release.tex \
		third-party.tex \
		titlepage.tex \
		sourceforge.tex \
        provided_tools.tex \
		toc.tex

# xfig figures.  .eps and .pdf files will be automatically generated
# from these.

FIG_FILES	=

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

EPS_FIG_FILES	= $(FIG_FILES:.png=.eps)

# Tell automake to include all the relevant files

EXTRA_DIST	= $(MAIN_TEX) $(OTHER_SRC_FILES) $(FIG_FILES)
CLEANFILES	= $(MAIN_PS) $(MAIN_DVI) $(MAIN_PDF) *~

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
$(MAIN_PDF): $(TEX_SRC) $(FIG_FILES)

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
