DESTDIR=

SCRIPTS := 	01_update_ubuntu_repo \
			02_update_repo_conffile
SUBDIRS := 

#doc:
#	install -d -m 0755 $(DESTDIR)$(MANDIR)/man1/
#	for bin in ${SCRIPTS} ; do ( pod2man --section=1 $$bin $(DESTDIR)$(MANDIR)/man1/$$bin.1 ) ; done

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install: 
	install -d -m 0755 $(DESTDIR)/usr/bin/oscar-updater.d
	install    -m 0755 $(SCRIPTS) $(DESTDIR)/usr/bin/oscar-updater.d
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)/usr/bin/system-sanity.d; rm -f $(SCRIPTS)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
