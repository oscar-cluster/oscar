# -*- mode: Makefile; -*-

LIBDIR	?= $(shell perl -V:vendorlib | cut -d"'" -f2)
MANDIR  ?= /usr/share/man
GIT_BRANCH ?= $(shell test -d .git && git branch |grep '^*'|cut -d' ' -f2)
