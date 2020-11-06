DESTDIR=
TOP_LIB_DIR = ../../..
include $(TOP_LIB_DIR)/Config.mk

SUBDIRS := 
FILES := yum.pm dnf.pm zypper.pm apt.pm urpmi.pm

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	@echo Creating $(DESTDIR)$(LIBDIR)/OSCAR/OCA/PM_Abstract
	install -d -m 0755 $(DESTDIR)$(LIBDIR)/OSCAR/OCA/PM_Abstract
	install    -m 0755 ${FILES} $(DESTDIR)$(LIBDIR)/OSCAR/OCA/PM_Abstract
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)$(LIBDIR)/OSCAR/OCA/PM_Abstract/*.pm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
