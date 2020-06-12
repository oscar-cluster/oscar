DESTDIR=
TOPDIR = ../..
include $(TOPDIR)/Config.mk

SCRIPTS_WITH_DOC := main_cli
SCRIPTS_WITHOUT_DOC := build_oscar_image_cli define_oscar_clients_cli \
		configurator_cli modules.used simple_complete.pl

SCRIPTS := $(SCRIPTS_WITH_DOC) $(SCRIPTS_WITHOUT_DOC)
SUBDIRS := 

doc:
	install -d -m 0755 $(DESTDIR)$(MANDIR)/man1/
	for bin in ${SCRIPTS_WITH_DOC} ; do ( pod2man --section=1 $$bin $(DESTDIR)$(MANDIR)/man1/$$bin.1 ) ; done

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install: doc
	install -d -m 0755 $(DESTDIR)/usr/bin
	install    -m 0755 $(SCRIPTS) $(DESTDIR)/usr/bin
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)/usr/bin; rm -f $(SCRIPTS)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
