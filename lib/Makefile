DESTDIR=

TOPDIR = .
include $(TOPDIR)/Config.mk

#SUBDIRS := OSCAR Qt Tk
SUBDIRS := OSCAR Tk

FILES := 

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
