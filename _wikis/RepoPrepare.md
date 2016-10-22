---
layout: wiki
title: RepoPrepare
meta: 
permalink: "/wiki/RepoPrepare"
category: wiki
---
<!-- Name: RepoPrepare -->
<!-- Version: 7 -->
<!-- Author: mledward -->

# Preparing package repositories

OSCAR needs to have access to the distribution packages (RPMs, etc...) in order to
resolve dependencies of OSCAR packages on the master node and be able to build the
client node images. Before starting the cluster installation you must prepare the package
repository, i.e. copy the distribution packages (RPMs) from the installation CD-ROMs or
DVD to the package repository directory.

### Old repository location

Until (and including) OSCAR version 4.2.1 only homogeneous clusters with the same
hardware architecture and distribution on master and client nodes were supported.
Therefore only one package repository was needed and all packages had to be copied
to the directory


    /tftpboot/rpm

before starting the cluster installation.

During the installation phase the OSCAR packages were also copied into that
package repository, making it difficult to keep the repository clean and updated.


### New repository location

Starting with OSCAR 5.0 the package repository structure has been redesigned by  [EF](/wiki/ErichFocht/) and split up such that multiple distributions and architectures can be supported in parallel. The new directory structure separates _distribution-_ and _OSCAR-_specific packages. The packages are separated by their architecture and distribution, the generic path being:


    /tftpboot/distro/$DISTRIBUTION-$VERSION-$ARCHITECTURE

The $VERSION number contains no information on the particular _update_, it is only the main version number of the distribution! The $ARCHITECTURE string can be one of the following: `i386, x86_64, ia64`. All ia32 architectures are treated as `i386` (which is the output of `uname -i` on the machines).

Supported distribution name and version examples:
| *distro name* | *version* | *architecture* | *repository path* |
| RedHat Enterprise Linux WS | 4 | i386 | /tftpboot/distro/redhat-el-ws-4-i386 |
| Fedora Core | 4 | x86_64 | /tftpboot/distro/fedora-4-x86_64 |
| CentOS | 4.3 | ia64 | /tftpboot/distro/centos-4-ia64 |
| Scientific Linux | 3.6 | i386 | /tftpboot/distro/scientificlinux-3-i386 |
| Mandriva Linux | 2006 | i586 | /tftpboot/distro/mandriva-2006-i386 |

Packages belonging to OSCAR will be copied to a different distro-arch dependent subdirectory located in *`/tftpboot/oscar/`*.

If you would like the distribution repository to support group information, eg. support for RPM groups like "X Window System", "GNOME Desktop Environment", then simply copy the `comps.xml` file from the distribution media (usually in eg. `Fedora/base/comps.xml`) to the distribution repository directory.  The presence of this file will be automatically detected and the repository will be built with support for group information.  This could then be used with yum(e) or via the `.rpmlist` for image creation.

### Remote (URL) Repositories

A new feature introduced in OSCAR 5.0 is the support of remote repositories. Instead of copying the distribution packages to a local directory on the master node one can create a file pointing to distribution repositories available on the internet. These repositories need to use the repomd metadata, i.e. be compliant with yum, up2date and similar smart package managers.

Instead of creating a package repository directory as described in the _New repository location_ section, create a file named

    /tftpboot/distro/$DISTRIBUTION-$VERSION-$ARCHITECTURE.url
and enter the repository URLs accessible on the internet, one per line. Usually you'll want to add one URL for the main distribution repository and one line for the updates. Lines starting with # are ignored.

Example for Fedora Core 4:

    # distro mirror site (this is not necessarilly the fastest...)
    http://download.fedora.redhat.com/pub/fedora/linux/core/4/i386/os/
    # updates mirror site
    http://download.fedora.redhat.com/pub/fedora/linux/core/updates/4/i386/
