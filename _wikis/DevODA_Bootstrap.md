---
layout: wiki
title: DevODA_Bootstrap
meta: 
permalink: "wiki/DevODA_Bootstrap"
category: wiki
---
<!-- Name: DevODA_Bootstrap -->
<!-- Version: 1 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > [ODA](DevODA)

## ODA Bootstrapping

The ODA bootstrap is composed of two stages:

 * stage 1: the installation of ODA files,
 * stage 2: the initialization of ODA based on user preferences (for instance, the usage of mysql versus postgresql).

### Bootstrap Stage 1

As a prereq for the usage of OSCAR, ODA needs to be installed. This is done via the usage of binary packages and the OSCAR prereq mechanism (actually the OSCAR prereq mechanism automatically install the ODA binary package). The ODA prereq definition can be see here: http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/share/prereqs/OSCAR-Database

After the prereq mechanisms installed the ODA binary package, it is then possible to move to stage 2 which in fact bootstrap ODA.

### Bootstrap Stage 2

This step allows one to initialize ODA based on the required actual configuration. For instance, if a given user wants to use the mysql database, first a configuration step is required before to actually initialize ODA. The ODA tool (http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oda/trunk/bin/oda) actually provides an option to perform the configuration automatically. For that, just use the following command: `oda --init <mysql|postgresql>`. This tool will create automatically few symlinks mandatory for the usage of ODA. Then, it is possible to bootstrap ODA, especially creation of the database, the creation of the tables and the population of the database with basic OSCAR data).

### How to Actually Bootstrap OSCAR?

Different solutions are possible depending on what you try to do:

 * if you just want to try to bootstrap ODA, outside of the context of the OSCAR bootstrapping, simply execute the `oda --init <mysql|postgresql>` command.
 * if you only care about the OSCAR bootstrapping, simply execute the `oscar-config --bootstrap` command.

### Resources & Development

ODA currently has his own development repository: http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oda
The installation of ODA can actually be done in 2 different ways:

 * Installation via a binary package, both an RPM and a Debian package are available via OSCAR online repositories.
 * Installation from source, in that case, simply execute the 'make install' command from the top level directory of the ODA source tree.
