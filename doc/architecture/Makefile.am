# -*- Makefile -*-
#
# $Id: Makefile.am,v 1.4 2001/12/22 01:08:36 jsquyres Exp $
#
# This file is part of the OSCAR distribution.
# See the copyright and license notices in the top-level directory.
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
		included-packages.tex

# xfig figures.  .eps and .pdf files will be automatically generated
# from these.

FIG_FILES	=

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

SUFFIXES	= .tex .dvi .ps .pdf .eps .fig

CHAP_CITE	= $(CHAP_CITE_TEX:.tex=)
MAIN_DVI	= $(MAIN_TEX:.tex=.dvi)
MAIN_PS		= $(MAIN_TEX:.tex=.ps)
MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)
EPS_FIG_FILES	= $(FIG_FILES:.fig=.eps)
PDF_FIG_FILES	= $(FIG_FILES:.fig=.pdf)

# Tell automake to include all the relevant files

EXTRA_DIST	= $(MAIN_TEX) $(OTHER_SRC_FILES) $(FIG_FILES)
CLEANFILES	= $(MAIN_PS) $(MAIN_DVI) $(MAIN_PDF)

# Some common target names

docs: pdf

ps: $(EPS_FIG_FILES) $(MAIN_PS) 
pdf: $(PDF_FIG_FILES) $(MAIN_PDF)

#
# Make the dependencies so that things build when they need to
#

$(MAIN_PS): $(MAIN_DVI)
$(MAIN_DVI): $(MAIN_TEX) $(OTHER_SRC_FILES) $(EPS_FIGURES)
$(MAIN_PDF): $(MAIN_TEX) $(OTHER_SRC_FILES) $(PDF_FIGURES)

#
# General rules
#

.fig.eps:
	$(FIG2DEV) -L eps $< $@

.fig.pdf:
	$(FIG2DEV) -L pdf $< $@

.tex.dvi:
	(unset TEXINPUTS; $(LATEX) $*)
	@if ( grep 'LaTeX Warning: Label(s) may' $*.log > /dev/null ); \
	then (unset TEXINPUTS; $(LATEX) $*) ; else :; fi
	@ if ( grep 'Writing index file' $*.log > /dev/null ); \
	then makeindex $* ; (unset TEXINPUTS; $(LATEX) $*) ; fi
	@-if ( grep 'LaTeX Warning: Citation' $*.log > /dev/null ); then \
	  if test "$(CHAP_CITE)" ; then \
	    for file in bogus $(CHAP_CITE) ; do \
	      if test "$$file" != "bogus"; then \
		bibtex $$file ; \
	      fi ; \
	    done ; \
	  else \
	    bibtex $* ; \
	  fi ; \
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
	  if test "$(CHAP_CITE)" ; then \
	    for file in bogus $(CHAP_CITE) ; do \
	      if test "$$file" != "bogus"; then \
		bibtex $$file ; \
	      fi ; \
	    done ; \
	  else \
	    bibtex $* ; \
	  fi ; \
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

# Deleting kruft temporary files

mostlyclean-generic:
	-rm -f *~ *.bak *% \
		  *.log *.aux *.dvi *.blg *.toc *.bbl *.lof *.lot *.out \
		  $(EPS_FIG_FILES) $(PDF_FIG_FILES)

