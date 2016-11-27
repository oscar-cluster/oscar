---
layout: wiki
title: GenericSetup
meta: 
permalink: "wiki/GenericSetup"
category: wiki
---
<!-- Name: GenericSetup -->
<!-- Version: 1 -->
<!-- Author: efocht -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure

## generic-setup
 
*generic-setup* is a script called during the installation phase which copies
the OSCAR binary packages which correspond to a particular distribution into the OSCAR
package repository.

*generic-setup* is currently also the standard way to organize binary packages belonging to an opkg in the opkg directory. Starting with OSCAR 5.0 only this directory structure is acceptable for opkgs and prereqs! The structure is (relative to the OSCAR package directory):

     SRPMS/               : source rpms location (not used by the code)
     distro/common-rpms/  : RPMs which are common to all RPM based distributions
     distro/$CDISTRO$VERSION-$ARCH/   : RPMs specific to the distribution $CDISTRO
                                      : with version $VERSION, on architecture $ARCH
     distro/common-debs/  : debian packages common to all debian related distros (not
                          : supported, yet)

The distribution name $CDISTRO is the distro name recognized by OSCAR, i.e. the so called compatible distro name (see [OS_Detect](DevOSDetect)). The compatible distro names known do OSCAR are listed in the table below. They have been chosen to be short strings in order to keep the distro/ subdirectory overseeable.

|*real distro*|*compat distro*|
|RedHat EL AS/ES/WS|rhel|
|CentOS|rhel|
|Scientific Linux|rhel|
|Mandriva|mdv|
|Mandrake|mdk|
|Fedora Core|fc|
|Debian|debian|

The introduction of *generic-setup* was very important enabling OSCAR to support multiple distributions. The structure allows the splitting of OSCAR into distro-independent and distro-specific tarballs (not implemented, yet).

### generic-setup invocation

This should not be needed as it is done through other OSCAR components.


    Usage: generic-setup [options] [pkg1 pkg2 ...]
    
      Scan the distribution specific directories distro/\$distro\$version-\$arch
      and the common directory (distro/common-rpms) for best packages for
      current or specified architecture (or noarch). Either copy the package
      files to the OSCAR package repository (/tftpboot/rpm) or delete them
      from there.
    
      If package names are passed as arguments, actions are limited to these
      packages.
    
      When copying in packages, if a file named \$pkg.txt exists, it will be
      displayed in the STDOUT of the command as comment.
    
     Options:
       --arch|-a      : override locally detected architecture
       --distro  D-V  : compatible distro-version string. The "-" is used for splitting! 
       --erase|-e     : erase packages with same name from package pool
       --help|-h      : display this help text
       --pool|-p path : override setting of package pool path
       --test|-t      : just test without really copying or erasing files
       --verbose|-v   : verbose printout
    

### Notes

`generic-setup` was introduced by [EF](ErichFocht) during OSCAR 4.2 development.

`generic-setup` has been stripped of package version comparison functionality. It might make sense to re-introduce this or add it to `install_prereq`.

`generic-setup` format is mandatory for OSCAR 5, it is called by `install_prereq` and `opkg-copy`.
