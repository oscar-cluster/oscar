---
layout: wiki
title: GSoC/NFS
meta: 
permalink: "wiki/GSoC/NFS"
category: wiki
folder: wiki
---
<!-- Name: GSoC/NFS -->
<!-- Version: 7 -->
<!-- Author: prg3 -->
Here's where some thoughts about the NFS project are going to live.

Major milestones

PHASE 1 - Learning[[BR]]
 1. Learn about the OPKG format:
    OSCAR packages are now "compiled" by OPKGC. Therefore, developers need to first "implement" the OPKG and then compile it.
       a. Where is the documentation about OPKGs?
       a. Is the documentation for the implementation of OPKGs up-to-date ?
       a. Where is the OPKGC documentation? At least a man page exists.
       a. Is the OPKGC documentation up-to-date?
 1. Build testing environment in VMWare
  a. CentOS 5.1 Headnode (x86_64)
  a. Solaris 10 NFS server
 1. Investigate current NFS code.
  a. Is it possible to separate the current NFS code from the core code and put NFS related stuff in a OPKG?
  a. <PG> It should be.. the existing NFS code should only be the disk files. <GV>Actually this is not only the disk files (i forgot about those) since there are several phases to setup NFS: installation/configuration of the server and then installation/configuration on clients.

PHASE 2 - Basics[[BR]]
 1. Implementation of a basic NFS support via a OPKG:
 1. Remove the NFS code from the core in the current core code.
   a. <GV> i guess here we could detail more: server configuration and then stuff we do on the client side.
 1. Creation a OPKG for NFS with a static configuration (similar to the configuration previously done).
 1. Validation (need to specify a set of tests for that).
    a. Test that NFS works as well as current. <GV>I developed a while ago a small generic tool for the implementation and execution of unit tests; that should ease your life and users life in the future.
    a. Add tests to test stage to ensure that all nodes work.
 1. Check-in in a branch or trunk (depending on the current status of trunk, i.e., on the merge of the 5,1 branch).
    a. <PG> Should this not be just trunk? <GV> If we can use trunk, we will use trunk, we need the stuff you will do and doing so, i am sure that will be integrated into OSCAR soon. :-)

PHASE 3 - Extended functionality[[BR]]
 1. Investigate and implement Automounter (AMD or AutoFS or both?)
 1. Add configuration options for multiple NFS servers and mountpoints.
   a. Where do we store this? <GV> Configurator should be able to give the entry point (get input from the user). Then we store the configuration data into ODA -- note that there is now a flat file version of ODA, you will be able to implement that easily (just create a specific file for OSCAR). We can decide to save configuration info into the real database later.
 1. Add to tests earlier to ensure all mountpoints are tested in the testing phase of deployment
   a. test mount at configuration stage from the headnode?
 1. Test outside of VMware.

PHASE 4 - Optimization (Optional from a GSoC perspective)
 1. Investigate jumbo frames option.  
   a. There are many things that can go wrong here, non-jumbo switch, non-supported nics on some machines
   a. We need to figure out if this is safe..
 1. NFS mountpoint tuning options added to configuration. (rsize, wsize, udp)

Completion Milestones:
 1. Commited OS_Settings to clean up OS conditional problems in install_server (and others) - June 10, 2008
