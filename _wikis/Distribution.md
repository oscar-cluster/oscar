---
layout: wiki
title: Distribution
meta: 
permalink: "wiki/Distribution"
category: wiki
---
<!-- Name: Distribution -->
<!-- Version: 1 -->
<!-- Author: efocht -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > Build System

## New Distribution Format
 
Starting with OSCAR version 5.0 (and the related beta versions) the distribution format is changed: OSCAR is distributed in a set of tarballs such that users can download exactly what they need for their cluster and avoid downloading the RPMs for distributions they don't care about.

The SVN repository looks exactly the way it looked before, i.e. with a packages/ subdirectory which contains all supported distribution's RPMs in the distro/ directory and a SRPMS/ subdirectory with the source packages for rebuilding RPMs. This is the normal setup for a developer.

The setup for a __user__ is stripped of all the distro/ subdirectories from inside the packages/ and share/prereqs/ directories (only the packman. yume and rapt packages will stay with base oscar, in order to ease the bootstrapping of the smart installer). All binary packages (AKA RPMs, currently) which are needed by the user are readilly set-up for installation in package repositories:

  * common-rpms: a common repository for all RPM based distros
  * $distro-$version-$arch: the distro/arch specific repository needed in addition to the common OSCAR packages.
The repositories come ready prepared with package metadata, such that the step of copying RPMs to the repository and preparing its metadata can be avoided, but the duplicate storage of data (inside the OSCAR installation and inside the repository), too.

The advantages of the new distribution format are:

 * save space: no need to keep RPMs in multiple places,
 * save space and download bandwidth: no need to download unnecessary RPMs for distros we don't care about,
 * save time during installation: no need to copy RPMs to repositories, no need to (re-)build the repository metadata during the install (though the repository metadata will be rebuilt if one invokes OPD),
 * flexibility: additional repositories can be downloaded anytime, 
 * central OSCAR repositories on the internet are now possible, thus allowing OSCAR installs without the need to download any OSCAR repositories. In this case all the user will need is the oscar-base tarball (5MB).
 * updating RPMs can be done either by adding the new RPMs to a repository (don't forget the metadata rebuild, the wizard will do it automatically) or accessing a special oscar-updates repository.
 
### Distribution Tarballs
 
 oscar-base-$(OSCAR_VERSION).tar.gz::
    Base oscar tarball for the users, stripped of almost all RPMs. Around 5MB in size. Unpacks into the directory oscar-$(OSCAR_VERSION).
 oscar-srpms-$(OSCAR_VERSION).tar.gz::
    Source RPMs for rebuilding RPMs. Optional. Around 90MB.
 oscar-repo-common-rpms-$(OSCAR_VERSION).tar.gz::
    Common repository for RPM based distros. Around 60MB large. Unpacks into the directory common-rpms. Should be untarred into /tftpboot/oscar. Will become optional once we have online repositories.
 oscar-repo-$distro-$version-$arch-$(OSCAR_VERSION).tar.gz::
    Distribution specific repository. Around 40MB large. Unpacks into the directory $distro-$version-$arch. Should be untarred in /tftpboot/oscar. Will become optional once we have online repositories.

