DESTDIR=

TOPDIR = ..
include $(TOPDIR)/Config.mk

SUBDIRS := HTML

FILES := HTML.pm Web.pm

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/Tk
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/Tk
	install    -m 0755 ${FILES} $(DESTDIR)$(LIBDIR)/Tk
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)$(LIBDIR)/Tk; rm -rf ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
