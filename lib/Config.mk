# -*- mode: Makefile; -*-

LIBDIR	?= $(shell perl -V:vendorlib | sed s/vendorlib=\'// | sed s/\'\;//)
