DESTDIR=
TOP_DIR = ..
include $(TOP_DIR)/Config.mk

SCRIPTS := create_and_populate_basic_node_info distro-query get_arch \
		get_num_proc get-oscar-version.sh install_prereq install_server \
		integrate_image mac_collector macinfo2sis OCA-driver opd oscar \
		oscar-config oscar_image_cleanup oscar_sanity_check oscar_wizard \
		ping_clients post_clients post_install post_rpm_install prepare_repos \
        prep_oscar_repos repo-update set_node_nics set_oscar_interface \
		setup_pxe ssh_install system-sanity update_live_macs wizard_prep \
		oscar-updater
SUBDIRS := cli system-sanity.d oscar-updater.d

doc:
	install -d -m 0755 $(DESTDIR)$(MANDIR)/man1/
	for bin in ${SCRIPTS} ; do ( pod2man --section=1 $$bin $(DESTDIR)$(MANDIR)/man1/$$bin.1 ) ; done

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
