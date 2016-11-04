---
layout: wiki
title: opkg_opkgc
meta: 
permalink: "wiki/opkg_opkgc"
category: wiki
---
<!-- Name: opkg_opkgc -->
<!-- Version: 6 -->
<!-- Author: bli -->

### OSCAR Package Compiler (OPKGC)

The OSCAR Package Compiler (OPKGC) aims at generate binary packages (both RPMs and Debian packages) from OSCAR packages
in order to ease their management and diffusion.

The idea of an OSCAR Package (OPKG) compiler has been defined and presented by Erich Focht during the OSCAR meeting in January 2007.

OPKGC is written in Python and use:
 * templating system Cheetah
 * ElementTree implementation for XML parsing and validation

Main features are:
 * validate opkg
 * generates RPM or .deb meta-files
 * generates RPM or .deb packages from meta-files
 * Currently supported output:
   * Fedora Core
   * RHEL
   * Mandriva
   * SuSe
   * Debian
 * contains a tool (opkg-convert) to migrate from old OSCAR package system to new description.

Latest release can be found here:
 * http://oscar.gforge.inria.fr/downloads/

### OPKGC Documentation

Full documentation is included with OPKGC distribution:
 * [../browser/pkgsrc/opkgc/trunk/doc/opkgc.1.html?format=raw opkgc] manpage
 * [../browser/pkgsrc/opkgc/trunk/doc/opkg.5.html?format=raw opkg] manpage: describe opkg format
 * full example of OSCAR package

### Automatic Generation of Binary Packages for a Specific Linux Distribution Using OPKGC

Every time a new Linux distribution and/or a new architecture has to be supported binary packages for OPKGs have to be generated using OPKGC. To ease this task the script 'compile_opkgs' is available. This script parses the default package set for the local Linux distribution, extract the list of supported OPKGs and try to compile them.
Generated binary packages are copied in '/tmp/opkgs'. Note that if you want to sign the generated binary package you should _not_ execute the script as root.

The script is available in 'pkgsrc/opkg'.
