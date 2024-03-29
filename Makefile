#  Makefile for OSCAR
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# $Id$
#
# Copyright (c) Erich Focht, NEC HPCE, Stuttgart, 2006
#               All rights reserved
# Copyright (c) Oak Ridge National Laboratory, 2007
#               Geoffroy Vallee <valleegr@ornl.gov>
#               All rights reserved
# Copyright (c) 2007 The Trustees of Indiana University.  
#               All rights reserved.

PKGDEST=.
DESTDIR=
TOPDIR  := $(CURDIR)
SUBDIRS := bin lib oscarsamples scripts utils share testing rpm images
SHELL := /bin/bash

include ./Config.mk

all:
	@echo "... there is no default target ..."
	@echo "Use one of: dist test install clean"

# DIKIM
# Since rpmbuild can not handle the character '-' in Version, remove the
# date(e.g.,'-20071225') part
OSCAR_VERSION ?= $(shell $(TOPDIR)/scripts/get-oscar-version.sh VERSION --full | cut -d- -f1)
OSCAR_BASE_VERSION ?= $(shell $(TOPDIR)/scripts/get-oscar-version.sh VERSION --base)
OSCAR_BUILD ?= $(shell $(TOPDIR)/scripts/get-oscar-version.sh VERSION --build-r | sed -e 's/[^0-9]//g')
OSCAR_RPM_VERSION ?= $(shell $(TOPDIR)/scripts/get-oscar-version.sh VERSION --rpm-v |cut -d- -f1)
OSCAR_RPM_RELEASE ?= $(shell $(TOPDIR)/scripts/get-oscar-version.sh VERSION --rpm-v |cut -d- -f2)

PKG        = $(shell env OSCAR_HOME=`pwd` OSCAR_VERBOSE=0 utils/distro-query | \
	       awk '/packaging method/{print $$NF}')
ARCH       = $(shell scripts/get_arch)

DIST_VER   = $(shell env OSCAR_HOME=`pwd` OSCAR_VERBOSE=0 utils/distro-query | \
	       awk '/compat distribution/{DIST=$$NF} \
	            /compat distrover/{VER=$$NF} \
		    END{print DIST"-"VER}')

test:
	@echo "Checking if distro is supported"
	perl -I$(TOPDIR)/lib $(TOPDIR)/utils/distro-query

# Use "make try_from_git" to install OSCAR to your system via GIT checkout
try_from_git: checkenv bootstrap-smart install-perlQt localrepos
	@echo "========================================================="
	@echo "!!! This is the tesing mode for the SVN repository    !!!"
	@echo "!!! Use it only if you know exactly what you are doing!!!"
	@echo "!!! If you want to _use_ OSCAR use \"make dist\"      !!!"
	@echo "========================================================="
	@echo "== building perl-Qt related programs =="
	(cd src; make)
	@echo "== building oscar repositories =="
	(export OSCAR_HOME=`pwd`; cd scripts; ./prep_oscar_repos)
	@echo "=============================================="
	@echo "== you can now run from the svn repository: =="
	@echo "==                                          =="
	@echo "== ./install_cluster INTERFACE              =="
	@echo "==                                          =="
	@echo "=============================================="

#
# EF: Docs are currently not built because that segfaults for me.
# Add "--docs" to the newmake.sh command line when it works.
#
dist:
	cd dist; ./newmake.sh --base --srpms --all-repos

# first attempt to include oscar-base rpms into common-rpms repo
nightly: nightly_version baserpms
	mkdir -p packages/base/distro/common-rpms
	mv oscar-*.rpm packages/base/distro/common-rpms
	cd dist; ./newmake.sh --base --srpms --all-repos
	rm -rf packages/base/distro/common-rpms ../oscar-base-*.tar.gz ../oscar-srpms-*.tar.gz

nightly_version:
	cd dist; ./newmake.sh --nightly; cd ..
#
# Install the repositories needed on the local machine to /tftpboot/oscar,
# Install the base OSCAR (without RPMS/DEBs) in /opt.
#
opt-install: localbase localrepos
	@echo "This machine is running: $(DIST_VER)-$(ARCH)"
	@echo "Native package manager: $(PKG)"
	@echo "== Installed OSCAR into $(DESTDIR)/opt/oscar-$(OSCAR_VERSION) =="

#
# Install the documentation
#
doc-install:
	install -d -m 0755 $(DESTDIR)$(DOCDIR)/oscar
	install    -m 0755 doc/*.pdf $(DESTDIR)$(DOCDIR)/oscar

#
# Install OSCAR (scripts, libs and so on) directly in the system.
#
install: doc-install
	# Install the OSCAR VERSION file
	install -d -m 0755 $(DESTDIR)/etc/oscar
	install    -m 0755 VERSION $(DESTDIR)/etc/oscar
	# Install the OSCAR common devel file(s)
	install -d -m 0755 $(DESTDIR)/usr/lib/oscar/build
	install    -m 0755 Config.mk $(DESTDIR)/usr/lib/oscar/build
	# Install the OSCAR opkg path (so it can belog to oscar-core package)
	install -d -m 0755 $(DESTDIR)/usr/lib/oscar/packages
	# Then, we call the different Makefiles.
	for dir in $(SUBDIRS) ; do ( cd $$dir ; $(MAKE) install ) ; done

localrepos:
	@echo "Creating local repositories"; \
	./scripts/prepare_repos $(DESTDIR);

#
# Install base OSCAR directly to /opt/oscar-$(OSCAR_VERSION)
# This is not containing package RPMs or SRPMS!!! It's for testing, only!
# Rebuild RPMs from the SVN checkout.
#
localbase: install-perlQt
	@if [ -d $(DESTDIR)/opt/oscar-$(OSCAR_VERSION) ]; then \
		echo "Directory $(DESTDIR)/opt/oscar-$(OSCAR_VERSION) already exists!";\
		echo "Refusing to continue.";\
		exit 1;\
	fi
	cd dist; ./newmake.sh --base --install-target $(DESTDIR)/opt


#
# Warning: the smart installer and perl-Qt won't be removed!
# 
clean:
	for dir in $(SUBDIRS) ; do ( cd $$dir ; $(MAKE) clean ) ; done
	#rm -rf tmp
	#rm -f oscar-base.spec
	rm -f *.rpm

bootstrap-smart:
	@echo "== bootstrapping smart installer =="
	@export OSCAR_HOME=`pwd`; \
	if [ "$(PKG)" = "rpm" ]; then \
		SMARTINST=packages/yume; \
	elif [ "$(PKG)" = "deb" ]; then \
		SMARTINST=packages/rapt; \
	fi; \
	scripts/install_prereq --dumb share/prereqs/packman $$SMARTINST

install-perlQt:
	@echo "== installing perl-Qt from share/prereqs =="
	@export OSCAR_HOME=`pwd`; \
	mkdir -p $$OSCAR_HOME/tmp; \
	scripts/install_prereq share/prereqs/perl-Qt

checkenv:
	@if [ -n "$$OSCAR_HOME" -a "$$OSCAR_HOME" != `pwd` ]; then \
		echo "*** OSCAR_HOME env variable is already defined ***"; \
		echo "*** and pointing to $$OSCAR_HOME               ***"; \
		echo "*** CANNOT CONTINUE! IT IS SAFER TO STOP HERE  ***"; \
		exit 1; \
	fi

opt-uninstall: clean
	@echo "Deleting directory $(DESTDIR)/opt/oscar-$(OSCAR_VERSION)"
	rm -rf $(DESTDIR)/opt/oscar-$(OSCAR_VERSION)
	@echo "Deleting directory $(DESTDIR)/tftpboot/oscar"
	rm -rf $(DESTDIR)/tftpboot/oscar
	rm -rf ~/tmp

tmp_source_tree:
	@rm -fr $(TOPDIR)/tmp
	@if [ -d $(TOPDIR)/.git ]; then \
		mkdir -p $(TOPDIR)/tmp/; \
		git archive --prefix=oscar-$(OSCAR_BASE_VERSION)/ $(GIT_BRANCH) | (cd $(TOPDIR)/tmp && tar xf -); \
	else \
		mkdir -p $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION); \
		(cd $(TOPDIR) && tar -cvf - \
		--exclude=tmp --exclude=.git --exclude=src --exclude=\*~ \
		--exclude=share/prereqs/\*/distro --exclude=share/prereqs/\*/SRPMS \
		--exclude=dist --exclude=\*.spec.in \
		.) | (cd $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION) && tar -xvf -); \
	fi

fixrev_tmp_tree: tmp_source_tree
	@for file in $$(grep -Erl '\$$Revision\$$|\$$Id\$$' $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION)/); do \
	    sed -i -e "s/\\\$$Revision\\\$$/$(OSCAR_VERSION)/g" -e "s/\\\$$Id\\\$$/$(OSCAR_VERSION)/g" $$file; \
	done
	@sed -i -e "s/__VERSION__/$(OSCAR_RPM_VERSION)/g" $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION)/oscar-core.spec
	@sed -i -e "s/__RELEASE__/$(OSCAR_RPM_RELEASE)/g" $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION)/oscar-core.spec

fixver_tmp_tree: tmp_source_tree
	@sed -e "s/^build_r=-1/build_r=r$(OSCAR_BUILD)/" \
	    < $(TOPDIR)/VERSION \
	    > $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION)/VERSION

source_tarball: fixrev_tmp_tree fixver_tmp_tree
	@echo "Creating OSCAR source tarball: $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION).tar.gz"
	@cd $(TOPDIR)/tmp && tar -ch oscar-$(OSCAR_BASE_VERSION) | gzip -9 > oscar-$(OSCAR_BASE_VERSION).tar.gz
	@echo
	@echo "source tarball has been created in $(TOPDIR)/tmp"
	@echo

baserpms: source_tarball
	@echo "Building OSCAR base rpms"
	@if [ `echo $(OSCAR_VERSION) | grep -c ':'` -gt 0 ]; then \
		echo "OSCAR_VERSION is $(OSCAR_VERSION) and contains a ':'"; \
		echo "Please clean up (svn update) your svn tree and try again!"; \
		exit 1; \
	fi
	@rpmbuild -tb $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION).tar.gz && \
	rm -rf $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION) $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION).tar.gz

moverpms: rpm
	@mv `rpm --eval '%{_topdir}'`/RPMS/noarch/oscar*$(OSCAR_BASE_VERSION)-*.noarch.rpm $(PKGDEST)
	@echo "Binary packages are available in $(PKGDEST)"


basedebs: source_tarball
	@echo "Building OSCAR base Debian packages"
	@if [ `echo $(OSCAR_VERSION) | grep -c ':'` -gt 0 ]; then \
		echo "OSCAR_VERSION is $(OSCAR_VERSION) and contains a ':'"; \
		echo "Please clean up (svn update) your svn tree and try again!"; \
		exit 1; \
	fi
	@if [ -n "$$UNSIGNED_OSCAR_PKG" ]; then \
		cd $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION) && \
		dpkg-buildpackage -rfakeroot -us -uc; \
	else \
		cd $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION) && \
		dpkg-buildpackage -rfakeroot; \
	fi ;\
	test $$? -eq 0 && rm -rf $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION) $(TOPDIR)/tmp/oscar-$(OSCAR_BASE_VERSION).tar.gz

movedebs: deb
	@mv /$(TOPDIR)tmp/*oscar*.deb $(PKGDEST);
	@echo "Binary packages are available in $(PKGDEST)"


deb: basedebs

rpm: baserpms

.PHONY : test dist clean install
