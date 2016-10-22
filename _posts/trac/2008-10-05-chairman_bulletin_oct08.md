---
layout: blog
title: Monthly Chairman Bulletin - October 2008
meta: Monthly Chairman Bulletin - October 2008
category: trac
folder: trac
---
<!-- Name: chairman_bulletin_oct08 -->
<!-- Version: 3 -->
<!-- Last-Modified: 2008/10/05 10:28:30 -->
<!-- Author: valleegr -->

We have a good news this month: *an alpha version of OSCAR-5.2 (in fact the SVN trunk) is available for Debian based systems* (i.e., Debian 4.0, ubuntu-7.10, and ubuntu 8.04)!

The major modifications for OSCAR-5.2 are:
 - support of online repositories (no need to create local repositories if your cluster headnode has access to internet),
 - the apparition of a new OSCAR component: the OSCAR Repository Manager (ORM), which provides an abstraction for the management of OSCAR repositories.
 - separation of OSCAR components that led to many bug fixes and enhancements (better documentation, more tests and so on).
Note that since we separate now the different OSCAR components, the current alpha version is only based on the OSCAR core (minimum to deploy a cluster, no extra OSCAR packages).

If you want to test this version, please refer to the following webpage:
https://svn.oscar.openclustergroup.org/trac/oscar/wiki/trunkTesting

If you encounter any problem, please send your bug reports to the oscar-devel mailing list.

We will prepare beta binary package for OSCAR as soon as few modifications will be finalized to support RPM based systems (some work needs to be done on Yume in order to make it compliant with the new PackMan extension). 

Stay tuned!
