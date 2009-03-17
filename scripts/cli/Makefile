DESTDIR=

SCRIPTS := build_oscar_image_cli define_oscar_clients_cli \
		configurator_cli main_cli modules.used simple_complete.pl
SUBDIRS := 

doc:
	install -d -m 0755 $(DESTDIR)/usr/local/man/man1/
	for bin in ${SCRIPTS} ; do ( pod2man --section=1 $$bin $(DESTDIR)/usr/local/man/man1/$$bin.1 ) ; done

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
