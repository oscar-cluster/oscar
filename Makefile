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
SUBDIRS := lib oscarsamples scripts share testing

include ./Config.mk

all:
	@echo "... there is no default target ..."
	@echo "Use one of: dist test install clean"

# DIKIM
# Since rpmbuild can not handle the character '-' in Version, remove the
# date(e.g.,'-20071225') part
OSCAR_VERSION ?= $(shell scripts/get-oscar-version.sh VERSION | cut -d- -f1)
PKG        = $(shell env OSCAR_HOME=`pwd` scripts/distro-query | \
	       awk '/packaging method/{print $$NF}')
ARCH       = $(shell scripts/get_arch)

DIST_VER   = $(shell env OSCAR_HOME=`pwd` scripts/distro-query | \
	       awk '/compat distribution/{DIST=$$NF} \
	            /compat distrover/{VER=$$NF} \
		    END{print DIST"-"VER}')

# Use "make test" to install OSCAR to your system via SVN checkout
test: checkenv bootstrap-smart install-perlQt localrepos
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
	mv oscar-base-*.rpm packages/base/distro/common-rpms
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
# Install OSCAR (scripts, libs and so on) directly in the system.
#
install:
	# Install the logo at destination (no Makefile to do so).
	install -d -m 0755 $(DESTDIR)/usr/share/oscar/images
	install    -m 0755 images/oscar.gif $(DESTDIR)/usr/share/oscar/images
	# Install the OSCAR VERSION file
	install -d -m 0755 $(DESTDIR)/etc/oscar
	install    -m 0755 VERSION $(DESTDIR)/etc/oscar
	# Then, we call the different Makefiles.
	for dir in ${SUBDIRS} ; do ( cd $$dir ; ${MAKE} install ) ; done

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
	(cd src; make clean)
	(cd doc; make clean)
	rm -rf tmp

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

baserpms:
	@echo "Building OSCAR base rpms"
	@if [ `echo $(OSCAR_VERSION) | grep -c ':'` -gt 0 ]; then \
		echo "OSCAR_VERSION is $(OSCAR_VERSION) and contains a ':'"; \
		echo "Please clean up (svn update) your svn tree and try again!"; \
		exit 1; \
	fi
	sed -e "s/OSCARVERSION/$(OSCAR_VERSION)/" < oscar-base.spec.in \
		> oscar-base.spec.tmp
	sed -e "s/PERLLIBPATH/$(SEDLIBDIR)/" < oscar-base.spec.tmp \
        > oscar-base.spec
	mkdir oscar-$(OSCAR_VERSION)
	cp -rl `ls -1 | grep -v oscar-$(OSCAR_VERSION)` oscar-$(OSCAR_VERSION)
	rm -f oscar-$(OSCAR_VERSION)/oscar.spec
	tar czvf oscar-$(OSCAR_VERSION).tar.gz \
		--exclude dist --exclude .svn --exclude \*.tar.gz \
		--exclude \*.spec.in --exclude src --exclude \*~ \
		--exclude share/prereqs/\*/distro \
		--exclude share/prereqs/\*/SRPMS oscar-$(OSCAR_VERSION)
	rm -rf oscar-$(OSCAR_VERSION)
	rpmbuild -tb oscar-$(OSCAR_VERSION).tar.gz && \
	mv `rpm --eval '%{_topdir}'`/RPMS/noarch/oscar*$(OSCAR_VERSION)-*.noarch.rpm $(PKGDEST) && \
	rm -f oscar-$(OSCAR_VERSION).tar.gz oscar-base.spec oscar-base.spec.tmp

basedebs:
	@echo "Building OSCAR base Debian packages"
	@if [ `echo $(OSCAR_VERSION) | grep -c ':'` -gt 0 ]; then \
		echo "OSCAR_VERSION is $(OSCAR_VERSION) and contains a ':'"; \
		echo "Please clean up (svn update) your svn tree and try again!"; \
		exit 1; \
	fi
	rm -rf /tmp/oscar-debian; mkdir -p /tmp/oscar-debian
	tar czvf /tmp/oscar-debian/oscar-base-$(OSCAR_VERSION).tar.gz \
        --exclude dist --exclude .svn --exclude \*.tar.gz \
        --exclude \*.spec.in --exclude src --exclude \*~ \
        --exclude share/prereqs/\*/distro \
        --exclude share/prereqs/\*/SRPMS .
	@if [ -n "$$UNSIGNED_OSCAR_PKG" ]; then \
		cd /tmp/oscar-debian && tar xzf oscar-base-$(OSCAR_VERSION).tar.gz && \
        dpkg-buildpackage -rfakeroot -us -uc; \
    else \
		cd /tmp/oscar-debian && tar xzf oscar-base-$(OSCAR_VERSION).tar.gz && \
        dpkg-buildpackage -rfakeroot; \
    fi
	mv /tmp/*oscar*.deb $(PKGDEST);
	@echo "Binary packages are available in $(PKGDEST)"

deb: basedebs

rpm: baserpms

.PHONY : test dist clean install
