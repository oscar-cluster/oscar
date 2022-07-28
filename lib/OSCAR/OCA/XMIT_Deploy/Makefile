DESTDIR=
TOP_LIB_DIR = ../../..
include $(TOP_LIB_DIR)/Config.mk

SUBDIRS := 

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/OCA/XMIT_Deploy
	@mkdir -p $(DESTDIR)$(LIBDIR)/OSCAR/OCA/XMIT_Deploy
	cp *.pm $(DESTDIR)$(LIBDIR)/OSCAR/OCA/XMIT_Deploy
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/OCA/XMIT_Deploy/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
