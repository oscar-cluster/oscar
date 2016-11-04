---
layout: wiki
title: trunkTesting
meta: 
permalink: "wiki/trunkTesting"
category: wiki
---
<!-- Name: trunkTesting -->
<!-- Version: 6 -->
<!-- Author: valleegr -->

# Testing OSCAR Trunk

## On Debian Based Systems

### Preliminary Notes
It seems that the Debian packages for SystemImager have issues during the installation on a fresh system: the installation of _systemimager--initrd-template-<arch>_ packages tend to fail during the OSCAR bootstrapping. In such a case, just install manually the package, forcing the installation. Then you should be able to run successfully "oscar-config --bootstrap".

If you face the problem, please send the error message on oscar-devel, so we can check that the problem is the same on all systems (then we will try to find a fix).

### Howto Test Trunk on Debian Based Systems

 1. As root, add the following line into your _/etc/apt/sources.list_:
  * On x86_64 systems: *deb http://bear.csm.ornl.gov/repos/debian-4-x86_64/ etch /*
  * On x86 systems: *deb http://bear.csm.ornl.gov/repos/debian-4-i386/ etch /*
 1. Execute as root *aptitude update*
 1. Make sure that your system is up-to-date
 1. Check-out OSCAR trunk
 1. Execute as root *make install*
 1. Execute as root *oscar-config --bootstrap*
 1. Execute as root *system-sanity* and make sure you address all the reported issues
 1. Execute as root *oscar-wizard install*

## On RPM Based Systems

 1. As root, add the following file into your _/etc/yum.conf.d_ directory: 
  * On x86_64 systems: [http://svn.oscar.openclustergroup.org/trac/oscar/attachment/wiki/repoTesting/CentOS-i386-OSCAR.repo]
  * On x86 systems: [http://svn.oscar.openclustergroup.org/trac/oscar/attachment/wiki/repoTesting/CentOS-x86_64-OSCAR.repo]
 1. Make sure that your system is up-to-date, executing as root *yum update*
 1. Check-out OSCAR trunk
 1. Execute as root *make install*
 1. Execute as root *oscar-config --bootstrap*
 1. Execute as root *system-sanity* and make sure you address all the reported issues
 1. Execute as root *oscar-wizard install*
