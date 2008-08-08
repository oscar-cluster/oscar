DESTDIR=
TOP_LIB_DIR = ..
include $(TOP_LIB_DIR)/Config.mk
SUBDIRS := 

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/ODA
	@mkdir -p $(DESTDIR)$(LIBDIR)/OSCAR/ODA
	cp *.pm $(DESTDIR)$(LIBDIR)/OSCAR/ODA
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/ODA/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
