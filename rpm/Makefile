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
	@echo Creating $(DESTDIR)/etc/yum.repos.d
	install -d -m 0755 $(DESTDIR)/etc/yum.repos.d
	install    -m 0755 oscar.repo $(DESTDIR)/etc/yum.repos.d
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
	cat oscar.list.in | sed -e "s|##SERVER_URL##|http://svn.oscar.openclustergroup.org|g" \
				-e "s|##REPO_PATH##|$$(./compute_repo_url repos)|g" > oscar.list

oscar.repo:
	cat oscar.repo.in | sed -e "s|##URL##|$$(./compute_repo_url http://svn.oscar.openclustergroup.org/repos)|g" \
				-e "s|##OSCAR_VERSION|$$(../scripts/get-oscar-version.sh ../VERSION --full)|g"  > oscar.repo

oscar.channel:
	cat oscar.channel.in | sed -e "s|##URL##|$$(./compute_repo_url http://svn.oscar.openclustergroup.org/repos)|g" > oscar.channel

sources.oscar.txt:
	cat sources.oscar.txt.in | sed -e "s|##URL##|$$(./compute_repo_url http://svn.oscar.openclustergroup.org/repos)|g" > sources.oscar.txt
clean:
	rm -f ${FILES}
	rm -f *~
