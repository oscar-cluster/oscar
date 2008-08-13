DESTDIR=
TOP_LIB_DIR = ../..
include $(TOP_LIB_DIR)/Config.mk

SUBDIRS := OS_Detect OS_Settings RM_Detect Sanity_Check

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/OCA
	@mkdir -p $(DESTDIR)$(LIBDIR)/OSCAR/OCA
	cp *.pm $(DESTDIR)$(LIBDIR)/OSCAR/OCA
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/OCA/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
