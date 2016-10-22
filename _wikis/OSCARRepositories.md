---
layout: wiki
title: OSCARRepositories
meta: 
permalink: "/wiki/OSCARRepositories"
category: wiki
---
<!-- Name: OSCARRepositories -->
<!-- Version: 9 -->
<!-- Author: valleegr -->

# OSCAR Repositories Management

## Introduction

Now that OSCAR packages are implemented via binary packages, the management of
binary package repositories becomes critical. The usage of repositories
typically aims to: (i) enable an easy management of OSCAR installation/
un-installation (for instance using aptitude on Debian or yum on RPM based
systems), and (ii) avoid the inclusion of binary packages in the SVN
repository. Therefore this is beneficial for both OSCAR users and developers.

Unfortunately, the creation of binary packages repositories is completely
different between the Debian and RPM world. As a result, it is not trivial to
setup repositories for OSCAR since political choices need to be made to
determine what repository organization should be used to provide both Debian
packages and RPMs for OSCAR.

For the usage of such repositories, tools for package upload and validation are
necessary (needed by developers). Some Linux distributions, such as Debian
already provide such tools, but an integration effort is needed. Also note that
the notion of validation is not more than checking the package to be sure the
comply with some basic rules (which needs to be determined based on their
binary package format). We also need developer tools for the creation of
packages for OSCAR packages.

Users also need to have special tools for the usage of OSCAR repositories. For
instance, tools for the creation of a local mirror of a given repository, based
on a specific architecture and Linux distribution.

This document aims at clarifying the different possibilities for the creation of
binary packages repositories, and also the selected solution. NOTE THAT THIS IS
STILL ONGOING WORK, THE IMPLEMENTATION MAY STILL BE INCOMPLETE.

## Definitions

### OSCAR

OSCAR is a set of tools aimed at deploying and configuring sets of machines. It
is composed of proper tools (OSCAR core) depending on 3rd party softwares.
OSCAR core plus software on which it depends compose the infrastructure of
OSCAR (OSCAR base).

### OSCAR packages (opkg)

OSCAR infrastructure can deploy regular RPM/deb packages but some softwares
need to use specific services provided by OSCAR infrastructure: they are Opkg OSCAR
packages ([wiki/Opkg]).

### OSCAR Version

Until here OSCAR is distributed as a whole set of software, mixing OSCAR base
and opkg. An OSCAR version refer to this frozen state of software, each with
their proper version.

From OSCAR 6.0, OSCAR version refer to OSCAR core version. All other software
(3rd party software + opkg) is linked to this version through RPM/deb
dependency relations. For instance:

  * oscar-core package version is 6.0
  * oscar-core depends on systemimager version superior or equal to 4.1.3,
  * On a given Linux distribution, systemimager available version is 4.1.6. If I install,

oscar-core, systemimager version 4.1.6 will be installed. Case of OSCAR
packages is exactly the contrary: they depend on a set of OSCAR version, for
instance superior or equal to 6.1, equal to 6.0, inferior to 6.2, etc.

Concretely, major changes between OSCAR version 5.x and OSCAR 6.0 is that, in
the first case, all relations between packages where 'equal to' while now we
want to make plain use of other kind of relations : 'greater than', 'less
than', etc.

The goal is to minimize links between OSCAR related software, and, given that,
minimize work to maintain OSCAR on a big set of distributions, as OSCAR project
has done until here.

## Standard Debian Based Repositories

The Debian world typically assumes a repository is for a given version of the
Debian distribution (e.g., Debian 4.0, Ubuntu 7.10). Therefore, for OSCAR, it
means that the repository name is not driven by the OSCAR version but by the
Debian version it is running on.

Moreover, binary packages for different architectures and distributions are
stored in a single pool. Debian tools for the generation of meta-data
repositories are actually in charge of figuring out which packages are for
which Linux distribution and which architecture. In other terms, the repository
meta-data tool is the smart tool for binary package repositories management on
Debian systems.

All needed tools exist:

  * repository metadata building
  * package checking
  * package upload queue managing
  * repository mirroring

### Advantages

Minimize the work to maintain the repositories (only one repository per Linux
distribution.

### Limitations

By default, only the latest version of OSCAR is available by default for a
given Linux distribution. If we decide to support multiple OSCAR release, the
common solution is too create a new namespace using a different package name.
For instance, the oscar-core package for OSCAR-6 could be named oscar6-core. Of
course, it implies extra work from the developers.

If a new version of OSCAR is available for a given Linux distribution, OSCAR
developers have to pay attention to the update procedure associated to binary
packages. For instance, if the database schema changes, developers have to
provide a script that will updated automatically the database.

## Standard RPM Based Repositories

Repositories for RPM are usually identified by a full "path". For instance,
http://mirror.centos.org/centos/5.0/os/x86_64/ is a repository for CentOS5
x86_64.

In other terms, the path of the repository is actually where semantic about the
repository is stored. The tool for the creation of repository meta-data is
actually pretty basic, simple.

Two options are therefore possible:

  * the OSCAR version appears in the path; in that case, OSCAR is more or less considered as a distribution,
  * the OSCAR does not appear in the path; OSCAR is not considered as a distribution. It implies a little bit more work from developers (more difficult to make the distinction between two OSCAR releases.

### Advantages

We can create a new repository for each OSCAR release, which simplifies the maintenance for a given OSCAR version.

No real need for update management (since repositories are separated, we can assume users will reinstall their system if they want to update OSCAR).

### Limitations

Multiplication of repositories which implies an increase of the complexity for their management.

Need to setup a repository for each new OSCAR release / Linux distribution / architecture.

## Selected Solution

### Overview

After discussion between developers, it seems that the solution that implies less effort is the creation of a repository per distribution and architecture (similar to the current architecture of the local OSCAR repositories). Another benefit of this approach is to enable the usage of OSCAR tools such as Packman, RAPT, and YUME.

### WebORM

WebORM allows the creation and the management of OSCAR repositories via a simple web-based user interface.
WebORM is available in '[pkgsrc/opkg/weborm](http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/opkg/weborm)'

WebORM has been deployed at IU for experimentation (you need to have a OSCAR account):
https://svn.oscar.openclustergroup.org/php/weborm/

### TODO List (needs to be updated)

In order to ease the management of OSCAR repositories, a set of tools are needed:

* tools for users
  * repository mirroring.

## Online OSCAR Repositories

This is the list of currently available online OSCAR repositories:
    * http://bison.csm.ornl.gov/repos/ Note that this repository is hosted at Oak Ridge National Laboratory in order to finalize and test tools for the management of OSCAR repositories. The creation of new accounts is limited and the machine can be removed at any time without notification.