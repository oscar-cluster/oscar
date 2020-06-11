# -*- mode: Makefile; -*-

SHELL = bash
.SHELLFLAGS = -ec
LIBDIR	?= $(shell perl -V:vendorlib | cut -d"'" -f2)
MANDIR  ?= /usr/share/man
DOCDIR  ?= /usr/share/doc
GIT_BRANCH ?= $(shell test -d .git && git branch |grep '^*'|cut -d' ' -f2)
