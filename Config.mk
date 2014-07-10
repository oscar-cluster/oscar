# -*- mode: Makefile; -*-

LIBDIR	?= $(shell perl -V:vendorlib | cut -d"'" -f2)
MANDIR  ?= /usr/share/man
