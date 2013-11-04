DESTDIR=
TOP_LIB_DIR = ../../..
include $(TOP_LIB_DIR)/Config.mk

SUBDIRS := 
FILES := debian debian5 debian6 default rhel rhel5 suse ubuntu1204

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/OCA/OS_Settings
	@mkdir -p $(DESTDIR)$(LIBDIR)/OSCAR/OCA/OS_Settings
	cp ${FILES} $(DESTDIR)$(LIBDIR)/OSCAR/OCA/OS_Settings
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/OCA/OS_Settings/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done
