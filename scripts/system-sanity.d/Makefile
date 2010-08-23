DESTDIR=

SCRIPTS := debrepo-check.pl display-check.pl network-check.pl \
		selinux-check.pl ssh-check.pl su-check.pl tftpboot-check.pl \
		yum-check.pl hostfile-check.pl
SUBDIRS := 

#doc:
#	install -d -m 0755 $(DESTDIR)/usr/local/man/man1/
#	for bin in ${SCRIPTS} ; do ( pod2man --section=1 $$bin $(DESTDIR)/usr/local/man/man1/$$bin.1 ) ; done

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install: 
	install -d -m 0755 $(DESTDIR)/usr/bin/system-sanity.d
	install    -m 0755 $(SCRIPTS) $(DESTDIR)/usr/bin/system-sanity.d
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)/usr/bin/system-sanity.d; rm -f $(SCRIPTS)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
