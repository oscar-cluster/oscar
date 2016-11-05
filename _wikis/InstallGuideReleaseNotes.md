---
layout: wiki
title: InstallGuideReleaseNotes
meta: 
permalink: "wiki/InstallGuideReleaseNotes"
category: wiki
---
<!-- Name: InstallGuideReleaseNotes -->
<!-- Version: 20 -->
<!-- Author: valleegr -->

[[TOC]]

[back to Table of Contents](InstallGuideDoc)

# Chapter 2: Release Notes

## <a name='releaseFeatures'></a>2.1 Release Features

The major new features for OSACR 6.x are:
 * OSCAR is not installed in /opt anymore but directly on the system (for instance, binaries are in /usr/sbin).
 * Full support of on-line repositories.
 * New bootstrapping mechanism.
 * Experimental support of Debian based systems.
 * Better error handling.
 * Source code reorganization, based on OPKGs classification.

For more details, please refer to the ChangeLog http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/ChangeLog

## <a name='generalNotes'></a>2.2 General Installation Notes

 * The OSCAR installer GUI provides little protection for user mistakes. If the user executes steps out of order, or provides erroneous input, Bad Things may happen. Users are strongly encouraged to closely follow the instructions provided in this document.
 * Each package in OSCAR has its own installation and release notes. See Section 6 for additional release notes.
 * Although OSCAR can be installed on pre-existing server nodes, it is typically easiest to use a machine that has a new, fresh install of a distribution listed in Table 1 with no updates installed. If the updates are installed, there may be conflicts in RPM requirements. It is recommended to install updates after the initial OSCAR installation has completed.
 * The "Development Tools" packages are not default packages in all distributions and are required for installation.
 * In some cases, the test window that is opened from the OSCAR wizard may close suddenly when there is a test failure. If this happens, run the test script, testing/test cluster, manually in a shell window to diagnose the problem.
 * OSCAR is currently fairly dependent on what language is enabled on the head node.  If you are running a non-english distribution, please execute the following command at your shell prompt before running the `install_cluster` script.

    export LC_ALL=C

## <a name='networkingNotes'></a>2.3 Networking Notes

 * All nodes must have a hostname other than `localhost` that does not contain any underscores "_" or periods "." Some distributions complicate this by putting a line such as as the following in /etc/hosts:


    127.0.0.1 localhost.localdomain localhost yourhostname.yourdomain yourhostname

If this occurs the file should be separated as follows:


    127.0.0.1 localhost.localdomain localhost
    192.168.0.1 yourhostname.yourdomain yourhostname

 * A domain name must be specified for the client nodes when defining them.
 * If ssh produces warnings when logging into the compute nodes from the OSCAR head node, the C3 tools (e.g., cexec) may experience difficulties. For example, if you use ssh to login in to the OSCAR head node from a terminal that does not support X windows and then try to run cexec, you might see a warning message in the cexec output:


    Warning: No xauth data; using fake authentication data for X11 forwarding.

Although this is only a warning message from ssh, cexec may interpret it as a fatal error, and not run across all cluster nodes properly (e.g., the <Install/Uninstall Packages> button will likely not work properly).

Note that this is actually an ssh problem, not a C3 problem. As such, you need to eliminate any warning messages from ssh (more specifically, eliminate any output from stderr). In the example above, you can tell the C3 tools to use the "-x" switch to ssh in order to disable X forwarding:


    # export C3_RSH=’ssh -x’
    # cexec uptime

The warnings about xauth should no longer appear (and the <Install/Uninstall Packages> button should work properly).

## <a name='selinuxNote'></a>2.4 SELinux Conflict

According to the NSA [http://www.nsa.gov/selinux/info/faq.cfm], the purpose of SE Linux is as follows: 

   * The Security-enhanced Linux kernel enforces mandatory access control policies that confine user programs and system servers to the minimum amount of privilege they require to do their jobs. When confined in this way, the ability of these user programs and system daemons to cause harm when compromised (via buffer overflows or misconfigurations, for example) is reduced or eliminated.

 * Due to issues with displaying graphs under Ganglia, and installing RPMs in a chroot environment (needed to build OSCAR images), SELinux should be disabled before installing OSCAR. During installation, it can be deactivated on the same screen as the firewall. If it is currently active it can be turned off using the selinux OSCAR package (make sure you manually select the selinux OSCAR package to do so).

## <a name='distributionNotes'></a>2.5 Distribution Specific Notes

 * This section discuss issues that may be encountered when installing OSCAR on specific Linux distribution versions/architectures.

### 2.5.1 RHEL 5
RHEL 5 users needs to create a local repository for RHEL 5 RPMs, right after the installation of the oscar RPM. For that, copy all RPMs from the installation CDs or DVD in _/tftpboot/distro/redhat-el-5-i386_ (*always replace i386 by x86_64 if you are using a x86_64 machine*). Note that RPMs may be in different directories on the CDs/DVD and you really need all of them. 
Then execute the following command as root: 
  * _yum update && yum -y install packman createrepo_
  * _cd /tftpboot/distro/redhat-el-5-i386 && packman --prepare-repo /tftpboot/distro/redhat-el-5-i386_.

### Ubuntu 12.04 (Precise)

#### Before Creating a Golden Image

Note that the Selector graphical interface does NOT work on Ubuntu 12.04 because it is based on Qt3 for Perl, which is not available on Ubuntu 12.04. If you really need to use Selector, please use the command line interface rather than the graphical interface to do so.

#### After Creating a Golden Image

* Update the SystemConfigurator Configuration File

There is currently a bug on Ubuntu that leads to the generation of an invalid configuration file within the image.

Please manually edit the following configuration file


    /var/lib/systemimager/images/<image_name>/etc/systemconfig/systemconfig.conf

Please update the content of the file to have something similar to:

    # systemconfig.conf written by systeminstaller.
    CONFIGBOOT = YES
    CONFIGRD = YES
    
    [BOOT]
        ROOTDEV = /dev/sda6
        BOOTDEV = /dev/sda
        DEFAULTBOOT = default
    
    [KERNEL0]
        PATH = /boot/vmlinuz-3.2.0-34-generic
        INITRD = /boot/initrd.img-3.2.0-34-generic
        LABEL = default

#### Before Imaging the Compute Nodes

* ATFTP

Before deploying your OSCAR cluster, you must update the atftp configuration file (*/etc/default/atftpd*). The content should like like the following:


    USE_INETD=true
    OPTIONS="--daemon --port 69 --tftpd-timeout 300 --retry-timeout 5     --mcast-port 1758 --mcast-addr 239.239.239.0-255 --mcast-ttl 1 --maxthread 100 --verbose=5  /tftpboot"

Change the value of *USE_INETD* to false:


    USE_INETD=false
    OPTIONS="--daemon --port 69 --tftpd-timeout 300 --retry-timeout 5     --mcast-port 1758 --mcast-addr 239.239.239.0-255 --mcast-ttl 1 --maxthread 100 --verbose=5  /tftpboot"

* SystemImager

Please refer to the notes at the following page:


    https://bitbucket.org/gvallee/systemimager-4.1.6-ubuntupreciseHome

#### After Imaging the Compute Nodes, On the Compute Nodes

Depending on the way the network domain was set up, the NFS mount may fail on the compute nodes: the file system is mounted but all directories in _/home_ are reported with a nobody user.

To address this issues, simply update the _Domain_ entry of your _/etc/idmapd_ configuration file to match your domain name.

To know what domain name is used, on the compute nodes, check the content of _/var/log/syslog/_ you should see something like

    nss_getpwnam: name 'user1@mydomain' does not map into domain 'localdomain'

The ''mydomain token is what you are looking for.

## <a name='pFilterNotes'></a>2.6 pfilter Notes

 * pfilter is the firewall which is bundled with OSCAR.  Besides its normal function as a firewall, it also provides NAT access for the compute nodes in your cluster

 * pfilter is currently unmaintained, and thus is not anymore included by default.
