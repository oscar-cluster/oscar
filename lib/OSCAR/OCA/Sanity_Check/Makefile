DESTDIR=
TOP_LIB_DIR = ../../..
include $(TOP_LIB_DIR)/Config.mk

FILES := Images.pm OPKG.pm Prereqs.pm
SUBDIRS := 

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check
	install    -m 0755 ${FILES} $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)$(LIBDIR)/OSCAR/OCA/Sanity_Check/; rm -f ${FILES}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
