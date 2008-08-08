DESTDIR=
TOP_LIB_DIR = ../..
include $(TOP_LIB_DIR)/Config.mk

SUBDIRS := 

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check
	@mkdir -p $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check
	cp *.pm $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
