---
layout: wiki
title: FedoraCore6
meta: 
permalink: "wiki/FedoraCore6"
category: wiki
---
<!-- Name: FedoraCore6 -->
<!-- Version: 5 -->
<!-- Author: bli -->

[Developer Documentation](wiki/DevelDocs) > [Distribution Support](wiki/DistroSupport) > Fedora Core 6

Basic support for Fedora Core 6 i386 has been added to trunk r5606.  Most OSCAR packages have been ommitted (see [browser:trunk/share/exclude_pkg_set/fc-6-i386.txt]).

Thanks to Allan Menezes, Fedora Core 6 x86_64 support has been added to trunk r5711.  This has not yet been fully tested.

If you would like to support any one of the missing packages, simply build the RPMs, put them in the respective directories in `/tftpboot/distro/oscar` and then remove the package name from the exclusion list. (The OSCAR developers would appreciate it if you send us the RPMs so that we can include them in our SVN repository for other users)

For more information about rebuilding RPMs, see DistroSupport.

If you encounter any other problems running OSCAR trunk with Fedora Core 6, please drop us a note at [mailto:oscar-devel@lists.sourceforge.net].

