---
layout: wiki
title: DistroSupport
meta: 
permalink: "wiki/DistroSupport"
category: wiki
---
<!-- Name: DistroSupport -->
<!-- Version: 55 -->
<!-- Author: olahaye74 -->

[Developer Documentation](DevelDocs) > Distribution Support

## Distribution Support for OSCAR >= 6.x

|Distribution\Arch       |x86_64 |
|---|---|
| Fedora 17       | ok |
| Fedora 18       | ok |
| Fedora 19       | ok |
| Fedora 20       | ok |
| CentOS / RHEL 7       | ok |
| CentOS / RHEL 6       | ok |
| Debian 6 / 7 (Ubuntu 12.04 / 12.10)  | ok |


Please refer to the documentation associated to each release to get the updated list of supported Linux distributions.

## Distribution Support for OSCAR < 6.x

The OSCAR project aims to support as many different Linux distributions as possible.  As such, when new codes are added to OSCAR (e.g., updated packages, new core component), they need to be ported/tested on previously supported distributions.

That usually involves rebuilding binary packages (eg. [RPMs](BuildRPM)) on the target platform and distribution and checking them into the source tree. For the Debian support, please visit the [OSCAR on Debian website](http://oscarondebian.gforge.inria.fr).

In the OSCAR release/checkout, there is a script called [browser:trunk/scripts/build_oscar_rpms build_oscar_rpms] which will help you build RPMs from OSCAR Packages on your running Linux distribution/architecture.  All you need to do is pass it the name(s) of OSCAR Package(s) and they will be built and copied to `packages/<package_name>/distro/<distro>-<arch>`.  If you are reasonably comfortable with building RPMs, this is an easy way to get RPMs built for an unsupported distribution/architecture quickly.  There are some documentation provided in the source code.

The new version(branch-5-1) of OSCAR requires to build [opkg meta rpms](opkgAPI) and there is a simple way to build the meta rpms [here](Building_Opkgs).

The following matrix lists people who intend to test on a particular distro/arch for the upcoming (5.1) release:

|Distribution\Arch    | x86     |x86_64 |ppc64 |
|---|---|---|---|
| Fedora Core 7       | Abhishek, DongInn (ok) | DongInn (ok)      |       |
| Fedora Core 8       | Abhishek, DongInn (ok) | Steven Blackburn, Allan Menezes[[BR]] DongInn (ok) |       |
| RHEL 4              | DongInn  (ok) | Michael, DongInn  (ok)   |       |
| RHEL 5              | DongInn  (ok) | Erich, DongInn  (ok)  |       |
| YellowDogLinux5.0   |         |       | DongInn  (ok)     |
| openSUSE 10.2       |  | Erich | |

For those of you who want to test oscar 5.1 b1, the tarballs for oscar 5.1 b1 are available [here](http://svn.oscar.openclustergroup.org/php/download.php?d_name=beta).[[BR]]
We usually support the most recently released distributions plus one version back.  But if there are developers/users who have the cycles to support other versions, then why not ;-)

If the linux distro remote repository is accessible, we can use it without copying all the rpms of the Linux installation CD/DVD to /tftpboot/distro/<distro_name>.
This is what I have used on my /tftpboot/distro/fedora-7-x86_64.url

    [donginn@f7-64 ~]$ cat fedora-7-x86_64.url 
    file:/tftpboot/distro/fedora-7-x86_64
    http://ftp.ussg.iu.edu/linux/fedora/linux/releases/7/Everything/x86_64/os
So, all you have to do is add the mirror site URL of the Linux distro to the .url file which OSCAR created for you or you can manually create.

## Distribution Specific Notes

### Fedora 7 / 8
Since the current version of Fedora uses the SATA subsystem, all the disk types are recognized as SATA (i.e., /dev/sd*) even though the actual disk type is IDE.
So, if you are setting up OSCAR with the IDE hdd on Fedora 7 / 8, you have to select "*UYOK*" at the step 6 "Setup Networking...". 

### openSUSE

If you are developing from a SVN checkout, the following RPMs need to be installed manually (via YaST, for instance):

 * perl-IO-Tty
 * perl-Qt
 * python-elementtree
 * yum

(and all the dependencies)
