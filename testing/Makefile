DESTDIR=
INSTALLDIR=/usr/lib/oscar/testing

SUBDIRS := unit_testing helpers tests.d apitests.d
SCRIPTS := run_unit_test testprint test_cluster ssh_user_tests

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	install -d -m 0755 $(DESTDIR)$(INSTALLDIR)
	install -d -m 0755 $(DESTDIR)$(INSTALLDIR)/data
	install    -m 0755 ${SCRIPTS} $(DESTDIR)$(INSTALLDIR)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)$(INSTALLDIR) ; rm -f ${SCRIPTS}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} clean ) ; done

