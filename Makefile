#  Simple Makefile for OSCAR
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
#


OSCAR_VERSION=$(dist/get-oscar-version.sh VERSION)


all:
	echo "... there is no default target ..."

test: install-packman
	@echo "========================================================="
	@echo "!!! This is the tesing mode for the SVN repository    !!!"
	@echo "!!! Use it only if you know exactly what you are doing!!!"
	@echo "!!! If you want to _use_ OSCAR use \"make dist\"      !!!"
	@echo "========================================================="
	@echo "===        building perl-Qt related programs          ==="
	@echo "========================================================="
	@echo "! If the following build fails, you are probably missing"
	@echo "! the perl-Qt package. Install it manually and retry.   "
	@echo "========================================================="
	(cd src; make)
	@echo "== building oscar repositories =="
	(export OSCAR_HOME=`pwd`)
	(cd scripts; ./prep_oscar_repos)
	@echo "==============================================="
	@echo "== you can now run from the svn repository:  =="
	@echo "== ./install_cluster INTERFACE               =="
	@echo "==============================================="

dist:
	cd dist; ./newmake.sh --base --srpms

clean:
	(cd src; make clean)
	(cd doc; make clean)
	rm -rf tmp

install-packman:
	export OSCAR_HOME=`pwd`
	scripts/install_prereq --dumb share/prereqs/packman

.PHONY : test dist clean install-packman
