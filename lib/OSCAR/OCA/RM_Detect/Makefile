DESTDIR=
TOP_LIB_DIR = ../../..
include $(TOP_LIB_DIR)/Config.mk

SUBDIRS := 
FILES := None.pm

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/OCA/RM_Detect
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/OSCAR/OCA/RM_Detect
	install    -m 0755 ${FILES} $(DESTDIR)$(LIBDIR)/OSCAR/OCA/RM_Detect
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/OCA/RM_Detect/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
