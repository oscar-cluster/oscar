---
layout: wiki
title: compile_core_opks
meta: 
permalink: "/wiki/compile_core_opks"
category: wiki
---
<!-- Name: compile_core_opks -->
<!-- Version: 4 -->
<!-- Author: valleegr -->

# Compile Core OPKGs

## On RPM Based Systems

On RPM based systems, please follow instrucation available there: [wiki/Building_Opkgs]

## On Debian Based Systems

First, you need to install [OPKGC](/wiki/opkg_opkgc/):
    1. Please, add the following line to your ''/etc/apt/sources.list'' file:
        * For x86 systems: ''deb http://bear.csm.ornl.gov/repos/debian-4-i386/ etch /''
        * For x86_64 systems: ''deb http://bear.csm.ornl.gov/repos/debian-4-x86_64/ etch /''
    1. As root, execute the following command: ''aptitude update''
    1. As root, execute the following command in order to install [wiki/opkg_opkgc OPKGC]: ''aptitude install opkgc''

## Compilation of Core OPKGS

Now, you need to compile the core OPKGs. The list of core OPKGs is: apitest, base, c3, oda, rapt, sc3, selinux, sis, switcher, sync-files, yume

