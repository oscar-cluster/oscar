---
layout: wiki
title: DistroPort
meta: 
permalink: "wiki/DistroPort"
category: wiki
---
<!-- Name: DistroPort -->
<!-- Version: 13 -->
<!-- Author: olahaye74 -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR Distribution Support

## Port to a New Linux Distribution

*WARNING, this documentation will work only for OSCAR-6.x*

### 1. 1st of All, you need to add support for this distro in OSCAR svn files

- oscar/share/etc/supported_distros.txt
- oscar/lib/OSCAR/OCA/OS_Detect/*
- oscar/lib/OSCAR/OCA/OS_Settings/*
- oscar/lib/OSCAR/Distro.pm
- oscar/oscarsamples/*
- oscar/share/package_sets/*
- pkgsrc/oda/trunk/etc/*.cfg

And optionally, if a new packaging system or/and a new package format is to be supported: (like urpmi or .pkg)

- oscar/lib/OSCAR/Bootstrap.pm
- oscar/lib/OSCAR/OpkgDB.pm
- oscar/lib/OSCAR/Prereqs.pm
- oscar/lib/OSCAR/OCA/OS_Detect/YourDistroType.pm
- oscar/lib/OSCAR/OCA/OS_Detect.pm
- oscar/lib/OSCAR/PackagePath.pm
- oscar/lib/OSCAR/Startover.pm
- oscar/lib/OSCAR/ConfigManager.pm
- oscar/lib/OSCAR/PackageInUn.pm (deprecated?)
- oscar/scripts/install_prereq
- oscar/Makefile # For make rpm or make deb...
- pkgsrc/packman/trunk/lib/<PKG>.pm
- pkgsrc/opkgc/*
- pkgsrc/oscar-packager/*
- All pkgsrc that have a Makefile with a rule to build the package like make deb or make rpm.

### 2. Then you need to bootstrap oscar-packager

For this document, we will assume you want to port trunk. To port OSCAR to a new Linux distribution perform the following steps:

On a yum based distro, you can use the following Quick start guide / script: DevelNewDistro

For other distro, you can try to follow the procedure below: (not up to date)
    1. Check-out oscar-packager:
        * svn co http://svn.oscar.openclustergroup.org/svn/oscar/pkgsrc/oscar-packager/trunk oscar_packager
    1. As root, install it on your system: ''cd oscar_packager; make install''.
    1. Please read the README file and follow instructions.
    1. As root, package the OSCAR core: ''oscar-packager --core unstable --debug''. All the binary packages should be saved in the ''/ftpboot/oscar/<distro_id>'' directory.
    1. As root, package the included OSCAR packages: ''oscar-packager --core unstable --debug''. All the binary packages should be saved in the ''/ftpboot/oscar/<distro_id>'' directory.

*Please, if you package OSCAR for a Linux distribution that is not yet officially supported by OSCAR, please contact OSCAR developers to share your packages and get some help from the community to maintain them.*
