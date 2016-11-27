---
layout: wiki
title: switcher
meta: 
permalink: "wiki/switcher"
category: wiki
---
<!-- Name: switcher -->
<!-- Version: 4 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure

## Switcher

### Introduction

The env-switcher package provides an convenient method
for users to switch between "similar" packages.  System- and
user-level defaults are maintained in data files and are examined at
shell invocation time to determine how the user's environment should
be set up.

The canonical example of where this is helpful is using multiple
implementations of the Message Passing Interface (MPI).  This
typically requires that the user's "dot" files are set appropriately
on each machine that is used since rsh/ssh are typically used to
invoke commands on remote nodes.

The env-switcher package alleviates the need for users to manually
edit their fot files, and instead gives the user commandline control
to switch between multiple implementations of MPI.

While this package was specifically motivated by the use of multiple
MPI implementations on OSCAR clusters, there is nothing specific to
either OSCAR or MPI in env-switcher -- switching between mulitple MPI
implementations is only used in this description as an example.  As
such, it can be used in any environment for any "switching" kind of
purpose.

Switcher does make sense on Debian based systems since Debian provides similar tools.

### Switcher and OSCAR

#### Overview

Switcher is actually composed of two parts: one which is the switcher project itself (env-switcher, available on SourceForge) and the switcher integration into OSCAR (typically the switcher OPKG).

If a given OPKG is the only one to declare switcher data, the values specified by this OPKG are considered as default values. If a default value already exists, the values are stored into ODA but not used as default; to use them as default, the user will have to explicitly use switcher.

#### How to use switcher?

Each OPKG can "declare" switcher data via a provide tag in the config.xml file. A example of such a tag is:


    <provide>mpi</provide>

Currently the storage of such data into ODA is done when executing [wizard_prep](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/wizard_prep), after the installation of the "api" binary packages of selected OPKGs. This is not a good solution long term (does not allow the usage of switcher in third party OPKG since switcher data won't be saved into ODA).

#### Implementation details

ODA is used to save switcher data. To access (read/write) switcher data into ODA, a Perl module is available providing a simple API: [SwitcherAPI](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/lib/OSCAR/SwitcherAPI.pm).

The switcher OPKG provide some glue code: this is the [package_config](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/packages/switcher/scripts/package_config.pm) Perl module. This module access ODA (using [SwitcherAPI](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/lib/OSCAR/SwitcherAPI.pm)) and reformat switcher data. This module should be merged with [SwitcherAPI](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/lib/OSCAR/SwitcherAPI.pm).

#### Future Improvements

Switcher data should be stored in ODA automatically. For that one solution is to write a 'switcher-oscar' tool that can store such information and modify OPKGC in order to understand this tool:
- OPKGC includes a call to the switcher-oscar tool in all OPKG (post_install of the api package) if the config.xml file has a reference to switcher (long-term, the config.xml files should be used only by OPKGC).
- OPKGC includes a dependency to switcher-oscar (api package).
- Since binary packages are installed before OPKG configuration, the storage of switcher info into ODA can be automatic.
