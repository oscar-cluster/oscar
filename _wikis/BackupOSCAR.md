---
layout: wiki
title: BackupOSCAR
meta: 
permalink: "wiki/BackupOSCAR"
category: wiki
---
<!-- Name: BackupOSCAR -->
<!-- Version: 10 -->
<!-- Author: bli -->
[Documentations](Document) > [Developer Documentations](DevelDocs) 

This document outlines the steps that need to be carried out to backup and restore a OSCAR headnode.

***NOTE*** These steps have been verified minimally - use only in an ***experimental*** environment and provide us with your comments/feedback at [oscar-devel](mailto:oscar-devel@lists.sourceforge.net).

### Backing up OSCAR

The following files/directories need to be backed up:

 * C3 configuration file
    * `/etc/c3.conf`
 * ODA (MySQL 'oscar' database):
    * Database backup
       * Run `scripts/oda dump <filename>`
       * Dump will be saved in `tmp/oda_dump`
    * Password
       * `/etc/oscar/odapw`
 * Hosts file
    * `/etc/hosts`
 * SSH-related files
    * `/etc/ssh/ssh_host*`
    * `/root/.ssh`
 * SystemImager images
    * `/var/lib/systemimager/images`
 * SystemImager scripts
    * `/var/lib/systemimager/scripts`
 * SystemImager overrides
    * `/var/lib/systemimager/overrides`
 * SystemImager configuration files
    * `/etc/systemimager`
 * SystemInstaller database
    * `/var/lib/sis`
 * tftpboot-related files
    * `/tftpboot/pxelinux.cfg`

### Restoring OSCAR

 * Re-install OS
 * Re-install OSCAR
    * Run `install_cluster` but quit the Wizard/CLI after completing step "Install OSCAR Server Packages"
 * Restore ODA dump
    * Run `scripts/oda restore <filename>`
 * Restore backed up files/directories:
    * `/etc/c3.conf`
    * `/etc/oscar/odapw` (restore password by running `scripts/oda reset_password`)
    * `/etc/hosts`
    * `/etc/ssh/ssh_host*`
    * `/root/.ssh/`
    * `/var/lib/systemimager/images`
    * `/var/lib/systemimager/scripts`
    * `/var/lib/systemimager/overrides`
    * `/etc/systemimager`
    * `/var/lib/sis`
    * `/tftpboot/pxelinux.cfg`
 * If clients are configured to network boot, re-run "Setup Network Boot"
 * And OSCAR is back...

