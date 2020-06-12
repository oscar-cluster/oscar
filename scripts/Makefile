DESTDIR=
TOPDIR = ..
include $(TOPDIR)/Config.mk

SCRIPTS_WITH_DOC := install_prereq install_server oscar-updater \
	oscar_sanity_check post_install ssh_install

SCRIPTS_WITHOUT_DOC := create_and_populate_basic_node_info \
		get-oscar-version.sh \
		integrate_image opd \
		ping_clients post_clients post_rpm_install \
		prep_oscar_repos set_node_nics \
		update_live_macs

SCRIPTS := $(SCRIPTS_WITH_DOC) $(SCRIPTS_WITHOUT_DOC)

SUBDIRS := cli oscar-updater.d

doc:
	install -d -m 0755 $(DESTDIR)$(MANDIR)/man1/
	for bin in ${SCRIPTS_WITH_DOC} ; do ( pod2man --section=1 $$bin $(DESTDIR)$(MANDIR)/man1/$$bin.1 ) ; done

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
