# -*- Makefile -*-
#
# $Id: Makefile,v 1.1 2001/08/14 18:17:53 jsquyres Exp $
#
# $COPYRIGHT$
#

# Program names.

LATEX		= latex
PDFLATEX	= pdflatex
DVIPS		= dvips
FIG2DEV		= fig2dev

# The top-level file.

MAIN_TEX	= development.tex

# All other .tex files that are necessary to build the paper (for
# dependencies).

OTHER_SRC_FILES	= \
		defs.tex \
		titlepage.tex \
		toc.tex \
		intro.tex \
		cvs.tex \
		directories.tex \
		files.tex \
		core.tex \
		third-party.tex

# xfig figures.  .eps and .pdf files will be automatically generated
# from these.

FIG_FILES	=

#########################################################################
#
# You should not need to edit below this line
#
#########################################################################

.SUFFIXES: .tex .dvi .ps .pdf .eps .fig

CHAP_CITE	= $(CHAP_CITE_TEX:.tex=)
MAIN_DVI	= $(MAIN_TEX:.tex=.dvi)
MAIN_PS		= $(MAIN_TEX:.tex=.ps)
MAIN_PDF	= $(MAIN_TEX:.tex=.pdf)
EPS_FIG_FILES	= $(FIG_FILES:.fig=.eps)
PDF_FIG_FILES	= $(FIG_FILES:.fig=.pdf)

# Some common target names
# Note that the default target is "ps"

ps: $(EPS_FIG_FILES) $(MAIN_PS) 
postscript: ps
pdf: $(PDF_FIG_FILES) $(MAIN_PDF)
acrobat: pdf

all: ps

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

#
# Standard targets
#

clean:
	/bin/rm -f *~ *.bak *% $(EPS_FIG_FILES) $(PDF_FIG_FILES)

distclean: squeaky
squeaky: clean
	/bin/rm -f *.log *.aux *.dvi *.blg *.toc *.bbl *.lof *.lot *.out \
		$(MAIN_PS) $(MAIN_DVI) $(MAIN_PDF)
