# -*- mode: Makefile; -*-

LIBDIR	?= $(shell perl -V:vendorlib | sed s/vendorlib=\'// | sed s/\'\;//)
# Ugly stuff the prepare LIBDIR for a usage with sed (extra "\" and so on).
SEDLIBDIR ?= $(shell perl -V:vendorlib | sed s/vendorlib=\'// | sed s/\'\;// | sed s/\'\;// | awk '{ gsub(/\//, "\\\\\/"); print}')
