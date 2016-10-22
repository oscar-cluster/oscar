---
layout: wiki
title: Repositories
meta: 
permalink: "/wiki/Repositories"
category: wiki
---
<!-- Name: Repositories -->
<!-- Version: 3 -->
<!-- Author: amitvyas -->

[[TOC]]

# OSCAR Packages Repositories

Most part of OSCAR are available as packages.

## APT

To make the OSCAR apt repository available from apt, add the correct `.list` file into `/etc/apt/sources.list.d/`:

 * [Debian Unstable (Sid)](http://oscar.gforge.inria.fr/oscar-debian-unstable.list)
 * [Debian Testing (Lenny)](http://oscar.gforge.inria.fr/oscar-debian-testing.list)
 * [Debian Stable (Etch)](http://oscar.gforge.inria.fr/oscar-debian-stable.list)

## YUM

To make the OSCAR yum repository available from yum, add the correct `.repo` file into `/etc/yum.repos.d/`:

 * [Fedora Core](http://oscar.gforge.inria.fr/oscar-fc.repo)
 * [RHEL](http://oscar.gforge.inria.fr/oscar-rhel.repo)
 * [SLES](http://oscar.gforge.inria.fr/oscar-sles.repo)
