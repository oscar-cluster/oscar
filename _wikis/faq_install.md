---
layout: wiki
title: faq_install
meta: 
permalink: "wiki/faq_install"
category: wiki
---
<!-- Name: faq_install -->
<!-- Version: 10 -->
<!-- Author: olahaye74 -->

[[TOC]]

[Back to the FAQ main page](faq)

# FAQ Related to Cluster Installation

## Compute nodes reboot after deployment and SELinux problems appear

When i deploy my nodes and they reboot, i have the following error:

    Unable to load SELinux Policy. Machine is in enforcing mode. Halting now.
    Kernel Panic - not syncing: Attempted to kill init!
The message means that the default SELinux policies are activated. To deactivate those rules, select the SELinux OPKG before to actually create the image; this OSCAR package aims at configuring the SELinux configuration.

## The "nc: connect: connection refused" appears several times during node imaging

This message is not related to any problem, they are generated during node imaging by SystemImager.

## During Step 4: Build OSCAR Client Image, the following message appears many times: "chown: cannot access `/etc/pki/tls/..."

The following messages may appear during the creation of an image on CentOS:

    chown: cannot access `/etc/pki/tls/private/exim.pem': No such file or directory
    chown: cannot access `/etc/pki/tls/certs/exim.pem': No such file or directory
    chmod: cannot access `/etc/pki/tls/private/exim.pem': No such file or directory
    chmod: cannot access `/etc/pki/tls/certs/exim.pem': No such file or directory

Those messages are a CentOS bug and do not affect OSCAR (they do not prevent the creation of a valid image):
http://bugs.centos.org/view.php?id=4014

## During Step 4: Build OSCAR Client Image, the following message appears many times: "Error: No matching Packages to list".

These messages can be ignored: when installing a binary package on RPM based systems using yum, a package on a given architecture may be available in different architecture dependent packages. For instance, on x86_64, the A RPM can be available both for i386 and x86_64. However, if the i386 RPM is installed, it may results in conflicts, therefore, we need to "detect" the best matching RPM before to actually install it. Doing this detection, the "Error: No matching Packages to list" message is generated every time we check a package for a given architecture and if the package is not available.
Also note that we cannot deactivate the output because of a bug in yum that prevent to redirect the output to /dev/null. This problem should be fixed in a future version of yum.

== How do I create an installation typescript? == #typescript

Using the script command to generate a log of operations you have done during the OSCAR installation is a tremendous help to developers who are trying to debug your problem.

Here's how to generate a typescript which you can attach to an email to [mailto:oscar-users@lists.sourceforge.net oscar-users] or [mailto:oscar-devel@lists.sourceforge.net oscar-devel] mailing-lists:

    [root@oscartst root]# script
    Script started, file is typescript
    [root@oscartst root]# cd /opt/oscar
    [root@oscartst oscar]# ./install_cluster eth0 &
    ...
    ...
    [root@oscartst oscar]# exit
    Script done, file is typescript

If your version of script supports the "-c" argument, you can simply execute:

    [root@oscartst oscar]# script -c './install_cluster eth0'

Please compress the file before posting to the mailing-list.

## I have this node that I want to re-image...

but my BIOS setting is set to boot off HD then network - is there a quick way around this?

Yes - you can mung your HD by doing the following after logging onto the node:

    dd if=/dev/zero of=/dev/hda count=2
Replace hda with sda if your HDs are SCSI.

This will zero your HD such that you won't be able to boot off it, then it will go straight to network boot.

## I noticed that xfs is using 99% CPU on my compute nodes, why's that?

This is because the font server failed to find certain fonts, and is hanging. Eg. on RHEL3, make sure that you have the 100dpi and 75dpi fonts installed:

    XFree86-100dpi-fonts-4.3.0-81.EL.i386.rpm
    XFree86-75dpi-fonts-4.3.0-81.EL.i386.rpm
Re-start `xfs` after you install the above 2 RPMs on the compute nodes and the problem will be resolved. 

## Some tests failed during test_cluster, now what?

You can try the following:

 * Run the tests again
 * Check the testing logs in `/home/oscartst` - eg. if you have failing PVM tests, look for .err files in the pvm directory
 * Increase the default_timeout variable in `/opt/oscar/testing/pbs_test` (OSCAR 4.2+) 

## The SIS kernel is too big to fit on a floppy disk, and my network card does not support PXE boot, how can I boot the nodes?

You can try to create a [Etherboot](http://etherboot.sf.net) floppy disk - this will allow you to boot up your compute nodes using the disk and subsequently boot off the network.

## The SystemImager kernel does not support my SATA/SCSI or network hardware, what can I do?

If you are using OSCAR 4.0 or 4.1, and the provided SystemImager kernel does not support your hardware, then you can try to use Peter Mueller's kernel which should support the latest and greatest SATA/SCSI/network drivers available for the 2.4 kernel.

For more information and downloads, follow this [link](http://wiki.sisuite.org/SystemImager).

For the impatient, simply download the following [kernel](http://world.anarchy.com/~peter/systemimager/kernel) and put it in `/tftpboot/` - this new kernel will be used to pxeboot your compute nodes.

If that does not solve your problem, it may be necessary to rebuild the SystemImager kernel to get your hardware supported.  If you would like a SystemImager or an OSCAR developer to help you, please make sure that you provide the following information in an email to either of the development lists ([mailto:sisuite-devel@lists.sourceforge.net sisuite-devel] or [mailto:oscar-devel@lists.sourceforge.net oscar-devel]):
 * Output of `lsmod`
 * Output of `lspci`
 * Output of `cat /proc/pci`

The best way to get these information is to boot a *compute node* with the Rescue CD of the Linux distribution you plan to install (usually the first CD).  Go into rescue mode by entering `linux rescue` at the boot prompt and you should be able to get the necessary information.

With newer SystemImager (3.7.x), you should be able to use UYOK (UseYourOwnKernel) to generate boot binaries (kernel, initrd.img, boel_binaries.tar.gz) from the Linux distribution you want to install - meaning if the Linux distribution supports your hardware, then SystemImager will too.  More information on UYOK when it is officially released.

## What do these error messages I get during Image Creation step mean?

During image creation step (Step 4: Build OSCAR Client Image), you may see error messages similar to the following:

    awk: cmd. line:2: fatal: cannot open file `/etc/fstab' for reading (No such file or directory)
    ls: readlink:: No such file or directory
    ls: file: No such file or directory
    ls: expected: No such file or directory
    awk: cmd. line:2: fatal: cannot open file `/etc/fstab' for reading (No such file or directory)
    awk: cmd. line:2: fatal: cannot open file `/etc/fstab' for reading (No such file or directory)
    ext2fs_check_if_mount: No such file or directory while determining whether /dev/loop0 is mounted.
    warning: can't open /etc/fstab: No such file or directory
    awk: cmd. line:2: fatal: cannot open file `/etc/fstab' for reading (No such file or directory)
These error messages can be safely ignored.

## What does the error message "undefined: DISK0" mean?

When you are in the process of imaging your nodes, you see a similar message as the following:

    This host name is:oscarnode1
    run_pre_install_script
    using autoinstall script: /scripts/oscaroscarnode1.sh write_variables run_autoinstall_script
    >>> /scripts/oscarnode1.sh
    get_arch
    DISKORDER = hd,sd,cciss,ida,rd
    enumerate_disks
    DISKS=0
    undefined: DISK0
    killing off running processes
    write_variables
    
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    This is system Installer auto install system .
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

This is because your hard drive is not supported by the SystemImager kernel - please refer to FAQ item about [SystemImager kernel](faq#TheSystemImagerkerneldoesnotsupportmySATASCSIornetworkhardwarewhatcanIdo) to solve this problem.

## What if the network boot fails?

If the nodes fail to retrieve an image when using the network boot option, there are several possible problems, listed here in no particular order.

 * Motherboard does not support PXE booting
   Older motherboards may not support network booting. You can try upgrading to the latest BIOS version by visiting the motherboard manufacturer's website.

 * Forgot to click on "Enable Network Boot" in the "Setup Networking" menu.
 
 * Network boot not highest priority in BIOS boot manager.
   The easiest way to set up a network boot is through the BIOS which is generally available at startup.
   Look for a "boot order" option and move the hard drive to the bottom. This will generally enable the system to boot off the network cards (which are frequently a bit harder to spot).

   It is possible to leave the boot order floppy/CD/HD/Network as it is frequently on shipping and still network boot by intentionally damaging the harddrive's boot sector.

## What if the SIS boot disk doesn't work?

If the boot disk generated by SIS doesn't clone a node successfully there are several possible causes (in no particular order).

 * The boot disk does not support the network card.

   The boot disk created by SIS contains many popular high speed network cards, but certainly not all of them. If this is a problem, see if your bios supports network booting and try that.
 * Firewall is incorectly configured on the head node.

   If pfilter is not correctly configured, or if other firewall software such as that installed by the distribution itself is active, then the nodes will not be able to communicate with the image server on the head node. Check the firewall set up to make sure that trafic on the local subnet is unrestricted.

## When installing Linux on my headnode, what type of installation should I choose?

If the particular Linux distribution you are installing has an option for a `workstation` install (eg. Fedora Core) - choose that. Otherwise, choose packages that you require but note that the following `server` packages should not be installed as they will conflict with the OSCAR installation:

 * mysql-server
 * tftp-server

## VMWare nodes have no network interface after being imaged

Newer distributions like RHEL-7 and derivatives dropped pcnet32 driver support.
Use the emulated Intel e1000 device, or preferably the paravirtualized VMWare vmxnet3 device
To do so, in the vmx file, search for "^ethernet0\." and Add the following line:

    ethernet0.virtualDev = "vmxnet3"
