---
layout: wiki
title: Building_OSCAR_Packages
meta: 
permalink: "wiki/Building_OSCAR_Packages"
category: wiki
---
<!-- Name: Building_OSCAR_Packages -->
<!-- Version: 5 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > Build OSCAR Packages

## How to generate the binary packages necessary for OSCAR

To generate all the binary package related to OSCAR, a tool has been developed to automate the process: _oscar-packager_. This tool also allows one to generate all the packages for almost any OSCAR-6.x release. Note that local repository are automatically created.

The latest version of the source code is available here: http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oscar-packager/trunk

To get the code, simply execute *svn co http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc/oscar-packager/trunk*

To install the code, simply execute *sudo make install* from the top directory of the source code.
For more details about know how to use the tool, simple refer to the man page: *man oscar-packager*.

You will also need some pre-required packages.

### Required packages for RPM based systems

On RPM based systems, you will have to execute the following command as root to ensure that all packages needed by oscar-packager are installed:

*yum install packman createrepo yume oscar-base*

### Required packages for Debian based systems

On Debian based systems, you will have to execute the following command as root to ensure that all packages needed by oscar-packager are installed:

*aptitude install oscar packman rapt*

