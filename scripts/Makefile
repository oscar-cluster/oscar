DESTDIR=
TOP_DIR = ..
include $(TOP_DIR)/Config.mk

SCRIPTS := create_and_populate_basic_node_info \
		get-oscar-version.sh install_prereq install_server \
		integrate_image opd \
		oscar_sanity_check \
		ping_clients post_clients post_install post_rpm_install \
		prep_oscar_repos set_node_nics \
		ssh_install update_live_macs \
		oscar-updater
SUBDIRS := cli oscar-updater.d

doc:
	install -d -m 0755 $(DESTDIR)$(MANDIR)/man1/
	for bin in ${SCRIPTS} ; do ( pod2man --section=1 $$bin $(DESTDIR)$(MANDIR)/man1/$$bin.1 ) ; done

all:
	for dir in ${SUBDIRS} ; do ( cd $$dir ; $(MAKE) all ) ; done

install: doc
	install -d -m 0755 $(DESTDIR)/usr/bin
	install    -m 0755 $(SCRIPTS) $(DESTDIR)/usr/bin
	for dir in $(SUBDIRS) ; do ( cd $$dir ; $(MAKE) install ) ; done

uninstall:
	cd $(DESTDIR)/usr/bin; rm -f $(SCRIPTS)
	for dir in $(SUBDIRS) ; do ( cd $$dir ; $(MAKE) uninstall ) ; done

clean:
	rm -f *~
