DESTDIR=
INSTALLDIR=/usr/share/oscar/testing/unit_testing

SUBDIRS := etc samples
SCRIPTS := test_config_file test_oscar_config test_systeminfo \
		test_configxml test_prereqs test_distro_detection test_repo_prep \
		test_network_utils test_image_mgt test_common_utils \
		test_systemservice test_repo_detection 

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install:
	install -d -m 0755 $(DESTDIR)$(INSTALLDIR)
	install    -m 0755 ${SCRIPTS} $(DESTDIR)$(INSTALLDIR)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	cd $(DESTDIR)$(INSTALLDIR) ; rm -f ${SCRIPTS}
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

clean:
	rm -f *~
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} clean ) ; done

