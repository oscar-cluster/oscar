---
layout: wiki
title: BuildOverview
meta: 
permalink: "wiki/BuildOverview"
category: wiki
---
<!-- Name: BuildOverview -->
<!-- Version: 1 -->
<!-- Author: efocht -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > Build System

## Build System Overview

The OSCAR build system has to take care of only a few very simple tasks:

 * build the documentation (invoke pdflatex on a few files)
 * build the few perl-Qt applications inside the src subdirectory by invoking puic
 * build the distribution tarballs

The former build system using autogen, autoconf, automake, configure, Makefile.am etc
was by far overdesigned for the simple tasks it had to accomplish. Especially the maintenance
and modification of the various Makefile.am files was useless work which had no real benefit.

The new build system is around 20 times faster than the old one, it builds the distribution tarballs in less than one minute on reasonably fast machines, is simpler to maintain and easier to adapt than the old one. It
is controlled by three components:

 * a central *Makefile* in the top directory
 * a set of Makefiles in the _src_ and _doc_ subdirectories which take care of building the documentation and the perl-Qt apps
 * *dist/newmake.sh*: a script which controlls the distro tarballs building.

### Make Targets

The central Makefile has following targets:
 make dist::
   Build all distribution tarballs, i.e. oscar-base, oscar-srpms, oscar-repo-common-rpms, various (all   supported) oscar-repo-$distro-$ver-$arch...
 make test::
   Prepare SVN checkout directory to be used for OSCAR testing. You can call "./install_cluster eth0" from its top directory, install a cluster, test things, without the need to install to a separate directory in /opt.
 make install::
   Install oscar-base to /opt/oscar-$(OSCAR_VERSION) and the repositories needed for the current distro/arch into /tftpboot/oscar/... This is skipping the tarball building step and is equivalent to building the tarballs and installing the ones you need for the current distro into /opt.
 make localbase::
   Install base OSCAR into /opt/oscar-$(OSCAR_VERSION). This is used internally by the "make install" target.
 make localrepos::
   Installs repositories needed for the distro/arch of the local machine to /tftpboot/oscar. Skips tarball creation and is internally used by "make install".
 make clean::
   Cleans up some things inside the SVN checkout directory. Removes the docs and the perl-Qt applications built in src/. You should invoke this after you called "make test" and are finished with testing.
