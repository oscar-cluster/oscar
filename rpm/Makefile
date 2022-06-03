DESTDIR=
TOPDIR = ..
include $(TOPDIR)/Config.mk

SUBDIRS := 
FILES := macros.oscar oscar.list oscar.repo oscar.channel sources.oscar.txt

OSCAR_ROOT_REPO_URL := http://olivier.lahaye1.free.fr/OSCAR
RELATIVE_REPO_PATH := $(shell $(TOPDIR)/rpm/compute_repo_url repos)
FULL_REPO_URL := $(shell $(TOPDIR)/rpm/compute_repo_url $(OSCAR_ROOT_REPO_URL)/repos)
DISTRO_CODENAME := $(shell perl -I$(TOPDIR)/lib $(TOPDIR)/scripts/distro-query --codename)
OSCAR_BASE_VERSION ?= $(shell $(TOPDIR)/scripts/get-oscar-version.sh $(TOPDIR)/VERSION --base)

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
	elif test -d /etc/yum/repos.d -o -d /etc/zypp/repos.d; \
	then \
		install -d -m 0755 $(DESTDIR)/etc/yum/repos.d; \
		install    -m 0755 oscar.repo $(DESTDIR)/etc/yum/repos.d/repo-oscar.repo; \
	fi
	if test -d /etc/zypp/repos.d; \
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
	@echo Uninstalling...
	rm -rf $(DESTDIR)/etc/rpm
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} uninstall ) ; done

macros.oscar:
	@echo creating macros.oscar
	cat macros.oscar.in > macros.oscar

oscar.list:
	@echo Creating oscar.list
	cat oscar.list.in | sed -e 's|##SERVER_URL##|$(OSCAR_ROOT_REPO_URL)|g' \
				-e 's|##REPO_PATH##|$(RELATIVE_REPO_PATH)|g' \
				-e 's|##DISTRO_CODENAME##|$(DISTRO_CODENAME)|g' > oscar.list

oscar.repo:
	@echo Creating oscar.repo
	cat oscar.repo.in | sed -e 's|##URL##|$(FULL_REPO_URL)|g' \
				-e 's|##OSCAR_VERSION##|$(OSCAR_BASE_VERSION)|g' > oscar.repo

oscar.channel:
	@echo Creating oscar.channel
	cat oscar.channel.in | sed -e 's|##URL##|$(FULL_REPO_URL)|g' > oscar.channel

sources.oscar.txt:
	@echo cfreating sources.oscar.txt
	cat sources.oscar.txt.in | sed -e 's|##URL##|$(FULL_REPO_URL)|g' > sources.oscar.txt
clean:
	rm -f ${FILES}
	rm -f *~
