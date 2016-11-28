---
layout: wiki
title: TipLDAP
meta: 
permalink: "wiki/TipLDAP"
category: wiki
---
<!-- Name: TipLDAP -->
<!-- Version: 2 -->
<!-- Author: jparpail -->
[Documentations](Document) > [User Documentations](Support) 

## Using LDAP authentication and LDAP based autofs with OSCAR

This document assumes you know how to set up individual computers to use your existing LDAP system.  It also assumes that you are using LDAP to mount your cluster `/home` directories via autofs, because I do.

This was developed and tested on OSCAR 5.0 on a 30 node cluster of Dell PE1950's using RedHat Enterprise Linux AS 4 Update 4.  Your mileage may vary.  A couple of the steps are specific to that hardware.

 * Install RHEL 4 - Add development tools at least, and graphical internet
 * run [http://linux.dell.com/files/name_eths/] to switch the eth0 and eth1 ports to match gig1 and gig2
 * Install OSCAR as described here [InstallGuide]
 * Gotchas:
   * Set `/etc/ssh.conf` to allowrootlogin yes
   * fix `/etc/hosts` so the localhost and hostname are in different lines.  hostname and public interface IP should be together.  Use a fake name for internal IP


    127.0.0.1 localhost.localdomain localdomain
    129.115.xxx.xxx cluster.cbi.utsa.edu cluster
    10.0.0.1 head.cbi.utsa.edu head

 * In Step 2: Select SGE package (which will remove Torque and Maui)
 * In Step 4: Build Clinet, select "Disk Partition File" = ./scsi.disk
 * (PE1955 Only)After Step 4: Exit the wizard and edit the following files (you'll have to add some directories, its ok)

`/var/lib/systemimager/overrides/oscarimage/etc/modprobe.conf`

    alias eth0 bnx2
    alias eth1 bnx2
    alias scsi_hostadapter mptspi
    alias scsi_hostadapter1 mptspi
    alias usb-controller ehci-hcd
    alias usb-controller1 uhci-hcd
    alias scsi_hostadapter2 mptsas
    alias scsi_hostadapter3 mptfc

`/var/lib/systemimager/scripts/pre-install/01all.load_sata_driver`

    #!/bin/sh
    #
      
    echo
    echo "loading ahci sata driver"
    echo
    modprobe mptspi
    modprobe mptsas
    modprobe mptfc

 * move local accounts (oscartst, mainly) to somewhere local, I picked `/localhome`. Change `/etc/passwd` to reflect this change.  Add `/localhome` to `/etc/exports` like the current `/home` mount (which you can remove).  Add the mount point `/localhome` to the file `/var/lib/systemimager/images/oscarimage/etc/fstab` as 

    head:/localhome /localhome      nfs     defaults        0 0

 * Configure head node for LDAP and mounting from your central file serverwith script
   * WARNING: This will make all your cluster users have passwordless ssh access to all your machines! This isn't a problem as long as you are aware of it.  It can be mitigated on individual servers I think.
 * reboot head node
 * check and make sure autofs and LDAP login are working
 * Set up head node for NAT (I used IP MASQ HowTo)
 * copy LDAP script to image temp directory /var/lib/systemimager/images/oscarimage/tmp/ for example and
 * chroot /var/lib/systemimager/images/oscarimage
 * run LDAP script from /tmp
 * mkdir /localhome; mkdir /groups 
 * exit chroot (don't restart autofs while in chroot, or probably any services, bad  things happen)
 * restart wizard and continue with step 5: Define OSCAR Clients
 * Continue wizard as in documentation until after all client nodes are defined and  imaged
   * Make sure you click on the "Enable UYOK" button before clicking on "Setup Network boot"! and give it a minute to complete the kernel transfer before you start collecting macs.  This way when you assign a mac, the node will be able to start imaging immediately (if you're quick).
 * Before running "Complete Cluster Setup" do the following or the tests will fail.
 * open a new terminal and do "su -"
 * scp node1:/etc/fstab .
 * edit fstab file to mount /localhome instead of /home from nfs_home
 * cpush fstab /etc/fstab
 * cexec "mount /localhome"
 * make sure ldap and autofs home directories are working on nodes
 * go back to wizard and run "Complete Cluster Setup" and "Test Cluster Setup" and  all tests ought to pass.

### Existing User Config

 * The first time on the cluster LDAP users must run "switcher mpi = lam-7.1.2" or some other valid mpi package, otherwise they don't have mpi path stuff.  Probably can fix this by using /etc/skel from the cluster, but I am not sure.
