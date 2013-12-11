DESTDIR=
INSTALLDIR=/usr/lib/oscar/testing/wizard_tests

SUBDIRS := helpers
SCRIPTS := all_nodes_up.apt before_step_2.apb before_step_5.apb before_step_8.apb \
           home_mounts_ok.apt SELinux_disabled.apt ssh_user_tests.apb before_step_0.apb \
           before_step_3.apb  before_step_6.apb  before_step_9.apb  IPV6_disabled.apt \
           ssh_node_to_server.apt  template_batch.apb before_step_1.apb  before_step_4.apb \
           before_step_7.apb ssh_server_to_node.apt template_test.apt true.apt

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

