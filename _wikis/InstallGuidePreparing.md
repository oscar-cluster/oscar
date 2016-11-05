---
layout: wiki
title: InstallGuidePreparing
meta: 
permalink: "wiki/InstallGuidePreparing"
category: wiki
---
<!-- Name: InstallGuidePreparing -->
<!-- Version: 30 -->
<!-- Author: olahaye74 -->

[[TOC]]

[back to the Table of Content](InstallGuideDoc)

# Chapter 3: Preparing to Install OSCAR

== 3.1 Installing Linux on the Server Node == #InstallLinux

To install OSCAR, your server node must have a linux distribution installed. It should be noted that OSCAR is only supported on the distributions listed in Table 1 (page 8). As such, use of distributions other than those listed will likely require some porting of OSCAR, as many of the scripts and software within OSCAR are dependent on those distributions.

When installing Linux, it is not necessary to perform a _custom_ install since OSCAR will usually install all the software on which it depends. The main Linux installation requirement is that some X windowing environment such as GNOME or KDE must be installed. Typically, a “Workstation” install yields a sufficient installation for OSCAR to install successfully.

*OSCAR-6.0.x assumes the server node has access to internet in order to be able to access on-line repositories. So, please, check that your server node has an active internet connection.*

== 3.2 Disk space and directory considerations == #DiskSpace

OSCAR has certain requirements for server disk space. Space will be needed to store the Linux binary packages and to store the images. The images are stored in _/var/lib/systemimager_ and will need approximately 2GB per image. Although only one image is required for OSCAR, you may want to create more images in the future. If you are installing a new server, it is suggested that you allow for 4GB in both the _/_ and _/var_ filesystems when partitioning the disk on your server.

If you are using an existing server, you will need to verify that you have enough space on the disk partitions. Again 4GB of free space is recommended under each of _/_ and _/var_.

You can check the amount of free space on your drive’s partitions by issuing the command *df -h* in a terminal. The result for each file system is located below the Available column heading.

The same procedure should be repeated for the _/var/lib/systemimager_ subdirectory, which will later contain the images used for the compute nodes.

== 3.3 Configuration for the Usage of the On-line OSCAR Repositories == #Repositories

Note that if you login as a regular user and use the su command to change to the root user, you must use *su -* to get the full root environment. Using `su` (with no arguments) is not sufficient, and will cause obscure errors during an OSCAR installation.

### 3.3.1 On CentOS/RHEL Based Systems

 1. As root:
yum -y install http://svn.oscar.openclustergroup.org/repos/unstable/<oscar_version>/<compat-distro-tag>/oscar-release-<version>-<release>.noarch.rpm

for instance, on rhel6 / centos6:

    yum -y install http://svn.oscar.openclustergroup.org/repos/unstable/rhel-6-x86_64/oscar-release-6.1.2r10778-1.el6.noarch.rpm

 1. Make sure that your system is up-to-date, executing as root *yum update*
 1. To install the OSCAR RPM, execute as root *yum install oscar*
 1. Check the content of the _/etc/oscar/oscar.conf_ file; make sure it matches your configuration (for instance check the OSCAR interface, i.e., the network interface used to manage your cluster, is correctly set).
 1. Execute as root *oscar-config --setup-distro <distro>-<version>-<arch>* (for instance *oscar-config --setup-distro centos-6-x86_64*). To get the full list of supported Linux distributions and get the exact syntax of the distribution identifier, please execute the *oscar-config --supported-distros* command.

### 3.3.2 On Debian-5,6 and Ubuntu Based Systems

 1. As root, add the following line into your _/etc/apt/sources.list_: 
  * On x86_64 systems: *deb http://svn.oscar.openclustergroup.org/repos/unstable/debian-7-x86_64/ wheezy /*
    * For the older version (e.g., Debian 5), '''deb http://bison.csm.ornl.gov/repos/debian-5-x86_64/ lenny /'''
  * i386 systems are not at the moment supported by the OSCAR tea
 1. Execute as root *aptitude update*
 1. Make sure that your system is up-to-date 
 1. To install the OSCAR Debian package, execute as root *apt-get install oscar* 
 1. Check the content of the _/etc/oscar/oscar.conf_ file; make sure it matches your configuration (for instance check the OSCAR interface, i.e., the network interface used to manage your cluster, is correctly set).
 1. Execute as root *oscar-config --setup-distro <distro>-<version>-<arch>* (for instance *oscar-config --setup-distro debian-4-x86_64* or *oscar-config --setup-distro ubuntu-1204-x86_64*). To get the full list of supported Linux distributions and get the exact syntax of the distribution identifier, please execute the *oscar-config --supported-distros* command.

