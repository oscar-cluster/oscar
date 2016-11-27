---
layout: wiki
title: DevODA_code
meta: 
permalink: "wiki/DevODA_code"
category: wiki
---
<!-- Name: DevODA_code -->
<!-- Version: 2 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > [ODA](DevODA)

## Code Source, Installation and Packaging

### Access to the source code

The ODA source code is available as a separate OSCAR module. Therefore, ODA has its own SVN repository: http://svn.oscar.openclustergroup.org/pkgsrc/oda.

### Code Structure

ODA is composed of scripts, Perl modules, few configuration "configuration files", and file specific the OPKG related to ODA (note that we use the standard naming rules):

 * scripts: http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oda/trunk/bin
 * Perl modules: http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oda/trunk/lib
 * Configuration files: http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oda/trunk/etc
 * OPKG specific scripts: http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oda/trunk/scripts

### Installation From Source Code

In order to install ODA on your system from source code, simply execute the standard _make install_ command from the top-level directory of the ODA (in trunk for instance, if you checked-out both trunk and tags).

### Installation From Binary Packages

Binary packages for ODA are available via online [OSCAR repositories](online_oscar_repos).

#### RPM Based Systems

 1. Update your Yum configuration to be able to use a online OSCAR repository (cf. yum documentation for more details).
 1. As root, execute the following command: ''yum install oda''.

#### Debian Based Systems

 1. Update your apt configuration to be able to use a online OSCAR repository (cf. apt documentation for more details).
 1. As root, execute the following command: ''aptitude install oda''.

### Creation of Binary Packages

#### RPM Creation

Simply execute the following command: _make rpm_

#### Debian Package Creation

Simply execute the following command: _make deb_
