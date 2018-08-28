---
layout: wiki
title: repoTesting
meta: 
permalink: "wiki/repoTesting"
category: wiki
---
<!-- Name: repoTesting -->
<!-- Version: 25 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > Testing

## Testing the OSCAR version available via our repositories

### Testing the latest release

#### On RPM Based Systems

 1. As root, add the following file into your _/etc/yum.repos.d_ directory: 
  * On x86_64 systems: [attachment:CentOS-x86_64-OSCAR.repo]
  * On x86 systems: [attachment:CentOS-i386-OSCAR.repo]
 1. Make sure that your system is up-to-date, executing as root *yum update* or *dnf update* or *zypper update*
 1. install the oscar-release package for your distro from http://svn.oscar.openclustergroup.org/repos/<oscar-version>/
 1. Check the content of the _/etc/oscar/oscar.conf_ file; make sure it matches your configuration (for instance check the OSCAR interface, i.e., the network interface used to manage your cluster, is correctly set).
 1. Execute as root *oscar-config --setup-distro <distro>-<version>-<arch>* (for instance *oscar-config --setup-distro centos-5-x86_64*). To get the list of Linux distributions officially supported by a given release of OSCAR, or get the exact syntax of the identifier you must use, you can execute the *oscar-config --supported-distros* command.
 1. Execute as root *oscar-config --bootstrap*
 1. Execute as root *system-sanity* and make sure you address all the reported issues 
 1. Execute as root *oscar_wizard install*

#### On Debian Based Systems

 1. As root, add the following line into your _/etc/apt/sources.list_: 
  * On x86_64 systems: *deb http://bison.csm.ornl.gov/repos/debian-4-x86_64/ etch /*
  * On x86 systems: *deb http://bison.csm.ornl.gov/repos/debian-4-i386/ etch /*
 1. Execute as root *aptitude update*
 1. Make sure that your system is up-to-date 
 1. Execute as root *apt-get install oscar* 
 1. Check the content of the _/etc/oscar/oscar.conf_ file; make sure it matches your configuration (for instance check the OSCAR interface, i.e., the network interface used to manage your cluster, is correctly set).
 1. Execute as root *oscar-config --setup-distro <distro>-<version>-<arch>* (for instance *oscar-config --setup-distro debian-4-x86_64*)
 1. Execute as root *oscar-config --bootstrap*
 1. Execute as root *system-sanity* and make sure you address all the reported issues 
 1. Execute as root *oscar_wizard install*

== Testing the development version == 

#### On RPM Based Systems (CentOS-5.x, RHEL-5.x, openSuse 10.x, and SuSe Entreprise 10.x)

 1. Follow [quick start guide](quick_start_guide_for_rhel)

#### On Debian Based Systems

 1. As root, add the following line into your _/etc/apt/sources.list_: 
  * On Debian 4 x86_64 systems: *deb http://bison.csm.ornl.gov/repos/unstable/debian-4-x86_64/ etch /*
  * On Debian 4 x86 systems: *deb http://bison.csm.ornl.gov/repos/unstable/debian-4-i386/ etch /*
  * On Debian 5 x86_64 systems (still experimental): *deb http://bison.csm.ornl.gov/repos/unstable/debian-5-x86_64/ etch /*
 1. Execute as root *aptitude update*
 1. Make sure that your system is up-to-date 
 1. Execute as root *apt-get install oscar* 
 1. Check the content of the _/etc/oscar/oscar.conf_ file; make sure it matches your configuration (for instance check the OSCAR interface, i.e., the network interface used to manage your cluster, is correctly set).
 1. Execute as root *oscar-config --setup-distro <distro>-<version>-<arch>* (for instance *oscar-config --setup-distro debian-4-x86_64*)
 1. Execute as root *oscar-config --bootstrap*
 1. Execute as root *system-sanity* and make sure you address all the reported issues 
 1. Execute as root *oscar_wizard install*

