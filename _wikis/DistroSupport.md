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
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR Distribution Support

## Distribution Support for OSCAR >= 6.x

|Distribution\Arch       |x86_64 |
|---|---|
| Fedora 27       | ok |
| Fedora 28       | ok |
| CentOS / RHEL 7       | ok |
| CentOS / RHEL 6       | ok |
| Debian 6 / 7 (Ubuntu 12.04 / 12.10)  | ok |
| Ubuntu 14.04  | ok |
| openSuSE 42.3  | in progress |


Please refer to the documentation associated to each release to get the updated list of supported Linux distributions.

## Distribution Support for OSCAR < 6.x

The OSCAR project aims to support as many different Linux distributions as possible.  As such, when new codes are added to OSCAR (e.g., updated packages, new core component), they need to be ported/tested on previously supported distributions.

That usually involves rebuilding binary packages (eg. [RPMs](BuildRPM)) on the target platform and distribution and checking them into the source tree. For the Debian support, please visit the [OSCAR on Debian website](OSCARonDebian).

In the OSCAR git repo, there are [dockerfiles](https://github.com/oscar-cluster/oscar/tree/master/support_files) which will help you bootstrap OSCAR build environment so you can build all the Packages for your running Linux distribution/architecture. All you need to do is install docker on your system and follow instructions in the dockerfile header comment.  If you are reasonably comfortable with building RPMs or DEBs, this is an easy way to get Packages built for an unsupported distribution/architecture quickly (just use a docker file that is similar to your distro, edit the FROM line and tweak the content, then use the container to check and port the packages)).

The following matrix lists people who intend to test on a particular distro/arch for the upcoming (6.5) release:

|Distribution\Arch    | x86     | x86_64 | ppc64 |
|---|---|---|---|
| RHEL 6              | N/A | Olivier (ok), DongInn | N/A      |
| RHEL 7              | N/A | Olivier (failed), DongInn | N/A      |
| YellowDogLinux5.0   | N/A        | N/A      | DongInn     |

## Distribution Support for OSCAR development releases

For those of you who want to test oscar 6.5 beta, the packages for oscar 6.5 beta are available [here](http://svn.oscar.openclustergroup.org/repos/unstable/).[[BR]]
We usually support the most recently released distributions plus one version back.  But if there are developers/users who have the cycles to support other versions, then why not ;-)

If the linux distro remote repository is accessible, we can use it without copying all the rpms of the Linux installation CD/DVD to /tftpboot/distro/<distro_name>.
This is what I have used on my /tftpboot/distro/fedora-7-x86_64.url

    [donginn@f7-64 ~]$ cat fedora-7-x86_64.url 
    file:/tftpboot/distro/fedora-7-x86_64
    http://ftp.ussg.iu.edu/linux/fedora/linux/releases/7/Everything/x86_64/os
So, all you have to do is add the mirror site URL of the Linux distro to the .url file which OSCAR created for you or you can manually create.

On RPM based distros, it's even easyer to install the oscar-release rpm which will automatically configure the package manager.
example for CentOS-7: rpm -ivh http://svn.oscar.openclustergroup.org/repos/unstable/rhel-7-x86_64/oscar-release-6.1.3-0.20180524.el7.noarch.rpm
(0.20180524 is the build release and is subject to change at each build; check what build is available by looking in the repo directory)

## Distribution Specific Notes

None.
