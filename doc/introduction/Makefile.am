# -*- Makefile -*-
#
# $Id: Makefile.am,v 1.1 2001/12/19 02:36:55 jsquyres Exp $
#
# $COPYRIGHT$
#

LATEX		= latex
FIG2DEV		= fig2dev
DVIPS		= dvips

# The top-level file.

MAIN_TEX	= intro.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		intro-refs.bib

# png figures.  .eps and .pdf files will be automatically generated
# from these.

PNG_FIG_FILES	=

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

SUFFIXES	= .tex .dvi .ps .pdf .eps

MAIN_DVI	= $(MAIN_TEX:.tex=.dvi)
MAIN_PS		= $(MAIN_TEX:.tex=.ps)
MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)

# Tell automake to include all the relevant files

EXTRA_DIST	= $(MAIN_TEX) $(OTHER_SRC_FILES) $(PNG_FIG_FILES)
CLEANFILES	= $(MAIN_PS) $(MAIN_DVI) $(MAIN_PDF) *~

# Some common target names

all: ps
docs: $(MAIN_PS)

ps: $(EPS_FIG_FILES) $(MAIN_PS)
pdf: $(PDF_FIG_FILES) $(MAIN_PDF)

#
# Make the dependencies so that things build when they need to
#

$(MAIN_PS): $(MAIN_DVI)
$(MAIN_DVI): $(MAIN_TEX) $(OTHER_SRC_FILES) $(EPS_FIG_FILES)
$(MAIN_PDF): $(MAIN_PS)

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

.ps.pdf:
	ps2pdf $*.ps $*.pdf

# Deleting kruft temporary files

mostlyclean-generic:
	-rm -f *~ *.bak *% \
		  *.log *.aux *.dvi *.blg *.toc *.bbl *.lof *.lot *.out \
		  $(EPS_FIG_FILES)
