CONFIGDIR=etc/oscar

SUBDIRS := prereqs package_sets

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	install -d -m 0755 $(DESTDIR)/$(CONFIGDIR)
	install -d -m 0755 $(DESTDIR)/$(CONFIGDIR)/templates
	install -d -m 0755 $(DESTDIR)/$(CONFIGDIR)/opkgs
	install    -m 0755 etc/supported_distros.txt $(DESTDIR)/$(CONFIGDIR)
	install    -m 0755 etc/core.conf $(DESTDIR)/$(CONFIGDIR)/opkgs
	install    -m 0755 etc/templates/oscar.conf $(DESTDIR)/$(CONFIGDIR)/templates
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -f $(DESTDIR)/$(CONFIGDIR)/supported_distros.txt
	rm -f $(DESTDIR)/$(CONFIGDIR)/templates/oscar.conf
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} clean ) ; done
