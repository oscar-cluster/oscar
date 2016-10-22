---
layout: wiki
title: DevOPD2
meta: 
permalink: "/wiki/DevOPD2"
category: wiki
---
<!-- Name: DevOPD2 -->
<!-- Version: 12 -->
<!-- Author: valleegr -->

OPD (OSCAR Package Downloader) has been modified to support modifications 
introduced by OPKGC. Since OSCAR packages are not shipped via binary packages,
the notion of OSCAR package repository did change: we now only deal with binary
package repositories (current Debian or yum repositories).
OPD therefore does not download anymore any packages. OPD allows:

  - to add new OSCAR repositories (needed for third-party OSCAR packages,

  - query local/online repositories to get information about available OSCAR repositories.

Because of that OPD becomes a tool for the management of OSCAR repositories
instead of a tool to download OSCAR repositories.
Furthermore, since everything is shipped via repositories, including core
OSCAR packages, it is possible to extend OPD to the management of third-party
repositories but also the default OSCAR repositories that are needed for the
installation of core OSCAR packages.

Therefore the new OPD includes several capabilites:

  - keep a list of OSCAR repositories,

  - for some or all repositories, get the list of available OSCAR packages,

  - keep a list of default OSCAR repositories.

For that the new OPD is actually composed of two differents components:

  - a command line tool which allows users to use OPD in interactive and non-interactive mode (based on the old OPD, before the introduction of OPKGC). This part of OPD is implemented in Perl and the non-interactive mode has been designed to be used by other tools (such as the graphical interface). The script is '$(OSCAR_HOME)/scripts/opd2'. For details about the usage of the opd2 tools are available when executing "opd2 --help".

  - a graphical tool which allows users to add repositories and query them about the available OSCAR packages. Note that since OPD2 does not download any OPKG   anymore (usage of online repositories), the GUI is named OSCAR Repository Manager (ORM). This tool is based on OPD in command line (non-interactive mode) and is implemented in C++/Qt4. The reason why the graphical interface was not implemented in perlQt are: 
    * the latest version of perlQt only support Qt < 3.3 which is a very old 
      version of Qt, note compliant anymore with Qt tools shipped in the major 
      Linux distributions.
    * C++/Qt4 is one of the latest technology for the creation of new GUIs.
    * because the script 'opd2' can be used in non-interactive mode, it is not
      necessary to use perl modules; therefore the usage of C++ does imply any
      conflict with the existing OSCAR code.
  At the same time, this is only a first implementation i quickly implemented; if need it is still possible to reuse .ui files and create the GUI in perlQt or any other language that can be used with Qt). The code is available in $(OSCAR_HOME)/src/ORM; it can be compiled executing 'make'.

Note that the new version of OPD can clearly populate the OSCAR database about
available OSCAR packages. However, the OSCAR development team did not agree yet
on this point and therefore the interface with ODA is not implemented.

# Todo List

  - clean up the code,

  - improve code comments,

  - use doxygen for the ORM code,

  - change the name of perl scripts, OPD2 does not make much sense since we do not download packages any more, we only deal with repository.

  - implement an interface with ODA?