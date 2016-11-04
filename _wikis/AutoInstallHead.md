---
layout: wiki
title: AutoInstallHead
meta: 
permalink: "wiki/AutoInstallHead"
category: wiki
---
<!-- Name: AutoInstallHead -->
<!-- Version: 13 -->
<!-- Author: valleegr -->

[Developer Documentation](DevelDocs) > Autoinstalling the headnode

# !!!WARNING!!!

'''THIS PAGE IS NOT MAINTAINED ANYMORE, SOME LINKS ARE DEAD. WE ONLY KEEP THIS PAGE FOR HISTORICAL REASON.
THIS PAGE IS DEPRECATED'''

# Autoinstalling the headnode

For development purposes, it is handy to be able to consistently rebuild your headnode for testing - some people like to take SystemImager images of the headnode, others like to use autoinstallation tools to re-install the headnode each time.  We list two common mechanisms for autoinstallation, kickstart for Red Hat/Fedora-based systems and AutoYaST for SUSE-based systems.

## Using Kickstart

If you are interested in using kickstart, then you can use this [attachment:ks.cfg] snippet as a base configuration for your kickstart script

This kickstart configuration works with Fedora Core 4.  Open it up using `ksconfig` and make modifications as necessary.  Although this is not exactly a "workstation" installation, the package selection is as close as possible to it.  So far it has worked without any problems.  You should also include in `%post` commands to copy the RPMs directly from the repository to `/tftpboot/distro/fedora-4-i386` etc.

To prepare a network RPM repository to kickstart Fedora Core 5, it is not sufficient to simply copy the `Fedora` directory from the distribution CDs to your file server - you also need to run the `createrepo` command in the directory where `Fedora` is located.  This will generate the `repodata` directory in the same path. (This also applies to CentOS 5)

An extended guide to auto-installing an OSCAR head node using kickstart and NFS can be found here:

http://www.union.ic.ac.uk/halls/garden/google/NFS.html


It is also possible to send the kickstart progress to a VNC Listener, this link will provide you with all the information you need:

http://fedora.redhat.com/docs/fedora-install-guide-en/fc5/sn-remoteaccess-installation.html#sn-remoteaccess-installation-vnclistener

## Using AutoYaST

[AutoYaST ](http://www.suse.com/~ug/autoyast_doc/index.html) is developed specifically for SUSE Linux and is quite similar to Kickstart in the sense that it allows you to define a template to automatically install a node with SUSE Linux.  It is however more powerful (and complicated) and is not as fast as Kickstart.

To create such a template, you need to have a running SUSE Linux system, then on the command line, invoke:


    yast2 autoyast

This will call up the GUI with steps to generate your template.

You can find a template for SUSE Linux 10.0 (OSS) [attachment:autoinst.xml here], however you *must* import this via the GUI and make modifications to things such as hostname, ips, root password, etc.

To setup PXE boot, you can use the following for your `/tftpboot/pxelinux.cfg/default` file:


    label suse10.0
            kernel suse10_0
            append initrd=suse10_0.img vga=normal hostip=192.168.0.2 netmask=255.255.255.0 \
                   gateway=192.168.0.1 nameserver=192,168.0.10 \
                   autoyast=nfs://192.168.0.1/var/local/linux/suse10.0/autoinst.xml \
                   install=nfs://192.168.0.1/var/local/linux/suse10.0/CD1/

To enable VNC, add `vnc=1 vncpassword=oscartest` before `autoyast=`.  You can then connect to the VNC session running on the headnode.

If you installed your headnode using AutoYaST, you need to first reboot the machine as the kernel loaded is the "default" kernel and there is no associated directory in /lib/modules.  If you try to install OSCAR, you will get an error message during the <Install OSCAR Server Packages> step when it tries to restart the NFS server:


    Shutting down kernel based NFS server..done
    Starting kernel based NFS serverFATAL: Could not load /lib/modules/2.6.13-15-default/modules.dep: No such file or directory
    ..failed

This happens on SUSE Linux 10.0 - not sure if this is fixed in future versions though...
