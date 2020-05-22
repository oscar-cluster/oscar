DESTDIR=
TOP_DIR = ..
include $(TOP_DIR)/Config.mk

SUBDIRS := 
FILES := macros.oscar oscar.list oscar.repo oscar.channel sources.oscar.txt

all:	$(FILES)
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} all ) ; done

install: all
	@echo Creating $(DESTDIR)/etc/rpm
	install -d -m 0755 $(DESTDIR)/etc/rpm
	install    -m 0755 macros.oscar $(DESTDIR)/etc/rpm
	@echo Creating yum repo dir in$(DESTDIR)
	if test -d /etc/yum.repos.d; \
	then \
		install -d -m 0755 $(DESTDIR)/etc/yum.repos.d; \
		install    -m 0755 oscar.repo $(DESTDIR)/etc/yum.repos.d; \
	elsif test -d /etc/yum/repos.d; \
	then \
		install -d -m 0755 $(DESTDIR)/etc/yum/repos.d; \
		install    -m 0755 oscar.repo $(DESTDIR)/etc/yum/repos.d/repo-oscar.repo; \
	fi
	if test -f /etc/zypp/repos.d; \
	then \
		install -d -m 0755 $(DESTDIR)/etc/zypp/repos.d; \
		install    -m 0755 oscar.repo $(DESTDIR)/etc/zypp/repos.d/repo-oscar.repo; \
	fi
	@echo Creating $(DESTDIR)/etc/apt/sources.list.d
	install -d -m 0755 $(DESTDIR)/etc/apt/sources.list.d
	install    -m 0755 oscar.list $(DESTDIR)/etc/apt/sources.list.d
	@echo Creating $(DESTDIR)/etc/smart/channels
	install -d -m 0755 $(DESTDIR)/etc/smart/channels
	install    -m 0755 oscar.channel $(DESTDIR)/etc/smart/channels
	@echo Creating $(DESTDIR)/etc/sysconfig/rhn
	install -d -m 0755 $(DESTDIR)/etc/sysconfig/rhn
	install    -m 0755 sources.oscar.txt $(DESTDIR)/etc/sysconfig/rhn
	@echo Creating $(DESTDIR)/etc/pki/rpm-gpg
	install -d -m 0755 $(DESTDIR)/etc/pki/rpm-gpg
	# Create the GPG keys
	# install    -m 0755 RPM-GPG-KEY-OSCAR $(DESTDIR)/etc/pki/rpm-gpg
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

uninstall:
	rm -rf $(DESTDIR)/etc/rpm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

macros.oscar:
	cat macros.oscar.in > macros.oscar

oscar.list:
	cat oscar.list.in | sed -e "s|##SERVER_URL##|http://www.usablesecurity.net/OSCAR|g" \
				-e "s|##REPO_PATH##|$$(./compute_repo_url repos)|g" > oscar.list

oscar.repo:
	cat oscar.repo.in | sed -e "s|##URL##|$$(./compute_repo_url http://www.usablesecurity.net/OSCAR/repos)|g" \
				-e "s|##OSCAR_VERSION##|$$(../scripts/get-oscar-version.sh ../VERSION --full)|g"  > oscar.repo

oscar.channel:
	cat oscar.channel.in | sed -e "s|##URL##|$$(./compute_repo_url http://www.usablesecurity.net/OSCAR/repos)|g" > oscar.channel

sources.oscar.txt:
	cat sources.oscar.txt.in | sed -e "s|##URL##|$$(./compute_repo_url http://www.usablesecurity.net/OSCAR/repos)|g" > sources.oscar.txt
clean:
	rm -f ${FILES}
	rm -f *~
