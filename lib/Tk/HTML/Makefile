DESTDIR=

TOPDIR = ../..
include $(TOPDIR)/Config.mk

SUBDIRS := 

FILES := Form.pm Handler.pm IO.pm

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/Tk/HTML
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/Tk/HTML
	install    -m 0755 ${FILES} $(DESTDIR)$(LIBDIR)/Tk/HTML
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)$(LIBDIR)/Tk/HTML; rm -rf ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
