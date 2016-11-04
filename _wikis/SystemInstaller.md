---
layout: wiki
title: SystemInstaller
meta: 
permalink: "wiki/SystemInstaller"
category: wiki
---
<!-- Name: SystemInstaller -->
<!-- Version: 3 -->
<!-- Author: valleegr -->

# Systeminstaller

## Building Process

Systeminstaller is available into the OSCAR svn repository under `pkgsrc/systeminstaller-oscar/trunk`.

In order to compile Systeminstaller, you need to execute `perl Makefile.PL && make`. Note that the building system for Systemimager is based on `ExtUtils::MakeMaker`. Therefore if you want to update the Makefile.PL, be sure you use the correct macros. For instance, do not make a direct reference to `/usr/bin/pod2man`, use the `pod2man` subroutine of the `ExtUtils::MakeMaker` Perl package. Another example, if you want to implement a new installation rule in the `Makefile.PL` file, be sure you use the variables that have *DEST* as prefix in order to avoid any issue during the building process.

## Build .deb Packages

to create .deb packages, just check out sources, generate the Makefile (`perl Makefile.PL`) and execute `make deb`. Created packages are in `/tmp/scdeb/` and the current created packages are systeminstaller-oscar and systeminstaller-oscar-x11.

## Build RPM Packages

We should use `make rpm`.

## Creation of the a New Release

Before to create new packages for systeminstaller-oscar, please update the version number into `Makefile.PL`, `sin-oscar.spec` and `debian/control`. Please also update the file `debian/changelog` (you may use the `dch` command for that).
