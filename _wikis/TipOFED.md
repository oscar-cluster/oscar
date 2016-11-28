---
layout: wiki
title: TipOFED
meta: 
permalink: "wiki/TipOFED"
category: wiki
---
<!-- Name: TipOFED -->
<!-- Version: 1 -->
<!-- Author: mledward -->
[Documentations](Document) > [User Documentations](Support) 

## Openfabrics (Infiniband) Setup
These are some notes on seting up the OpenFabrics 1.2.5 infiniband driver/utility/mpi package set from source on an OSCAR 5.0 cluster.  I successfully installed OFED on RHEL 4, but your milage may vary.

  * Install OSCAR 5.0 up through step 3 "Install Server Packages" as described in the installation guide ([http://svn.oscar.openclustergroup.org/trac/oscar/wiki/InstallGuideClusterInstall])
  * Get OFED source ([http://www.openfabrics.org/builds/ofed-1.2.5/release/])
  * yume install tcl-devel 

  * Make a new rpm list in /opt/oscar/oscarsamples/your.rpmlist (copy the one for the distro you are using)and add these rpms to the end of the list (in addition to the LDAP ones if you want to use those)

        #added for OFED
        tcl-devel
        kernel-devel
        kernel-smp-devel
        rpm-build
        sysfsutils
        sysfsutils-devel
        pciutils-devel

  * Reopen the OSCAR wizard and make a new image called myimage-OFED-source using /opt/oscar/oscarsamples/your.rpmlist and /opt/oscar/oscarsamples/scsi.disk 
  * Copy the OFED source to the image directory (cp OFED-1.2.5.tgz /var/lib/systemimager/images/myimage-OFED-source/tmp)
  * chroot /var/lib/systemimager/images/myimage-OFED-source 
  * untar source 
  * go into source directory and run ./install.sh 
  * Select option 3) Install everything 
  * I skipped IBoIP or whatever, since I don't care about making another TCP/IP stack to confuse things 
  * Set head node 10.0.0.1 as gateway, I think 
  * Had a spinner lock up in chroot and had to escape (ctl+c) out of that part of the install, doesn't seem to have broken anything important (to me)
  * go back and redefine all the nodes (delete and make them again) 
  * reimage 
  * Test

           * cexec "ibv_devinfo | grep ACTIVE"
                  o state: PORT_ACTIVE (4)
  * Repeat source installation on head node if desired 

  * SGE queue problem with open mpi and infiniband (RHEL4): http://gridengine.sunsource.net/servlets/ReadMsg?list=users&msgNo=17060
  * Make a new switcher module for open mpi
