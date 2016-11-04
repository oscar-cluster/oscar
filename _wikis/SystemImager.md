---
layout: wiki
title: SystemImager
meta: 
permalink: "wiki/SystemImager"
category: wiki
---
<!-- Name: SystemImager -->
<!-- Version: 3 -->
<!-- Author: bli -->

[Cluster Administrator Documentation](wiki/UserDocs) > SystemImager

# SystemImager

[SystemImager](http://www.systemimager.org) is the tool that OSCAR uses for deploying images to cluster nodes.  It is part of a bigger suite of tools called the System Installation Suite (thus the package name in OSCAR is SIS).

SystemImager is responsible for deploying the OS image to your compute nodes over the network.  It supports (as of version 3.7.3) three different transports: `systemimager-rsync` (default), `systemimager-multicast` (flamethrower), and `systemimager-bt` (bittorrent).

SystemImager ships with its own kernel and ramdisk (initrd.img) used for starting up a minimal system for imaging your nodes.  Although the SystemImager developers try their best to keep this kernel up-to-date with new hardware modules support, this is not always possible.  Therefore, starting in version 3.6.x, a new functionality called UseYourOwnKernel (UYOK) was introduced.

Let's say that you have installed a Linux distribution that supports your hardware on the server, UYOK allows you to take the running kernel (from the Linux distribution) and uses that as the SystemImager boot kernel.  This, combined with a ramdisk generated on the fly from an architecture specific `initrd_template` package (eg. `systemimager-i386initrd_template`) allows the user to be able to boot and image a node as long as the target OS to be deployed supports the hardware.

This should hopefully solve 99% of all hardware/module related issues with SystemImager. :-)

To use UYOK to generate a kernel/ramdisk pair, execute the following command on the headnode:


    # si_prepareclient --server servername --no-rsyncd

If you specify the `--no-rsyncd` argument, it will not restart `rsyncd`.

The resulting kernel and ramdisk will be stored in `/etc/systemimager/boot`.  Now copy these files to `/tftpboot` if you are PXE-booting.  Make sure to edit your `/tftpboot/pxelinux.cfg/default` file with a sufficiently large `ramdisk_size` in the kernel append statement, eg.:


    LABEL systemimager
    KERNEL kernel
    APPEND vga=extended initrd=initrd.img root=/dev/ram MONITOR_SERVER=192.168.0.2 MONITOR_CONSOLE=yes ramdisk_size=80000

Now SystemImager will use the UYOK boot package (which should recognize your hardware) to boot your nodes and successfully image them.

The above mentioned steps are automatically done for you if you check the "Enable UYOK" button in the "Setup Networking" step and then either select "Build AutoInstall CD..." or "Setup Network Boot".
