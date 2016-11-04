---
layout: wiki
title: OscarWizard
meta: 
permalink: "wiki/OscarWizard"
category: wiki
---
<!-- Name: OscarWizard -->
<!-- Version: 10 -->
<!-- Author: bli -->

# OSCAR Wizard

The OSCAR Wizard is the main GUI that OSCAR users interacts with and contains easy steps to build, configure and manage a OSCAR cluster.  Since OSCAR 5.0, the OSCAR Wizard is broken into two different modes - one for installation and the other one for management.

## Installation Mode

This is the default mode if you invoke the wizard via `install_cluster` or `scripts/oscar_wizard` - this mode has interfaces that allow you to build your cluster:

[attachment:oscar_wizard_install.png OSCAR Wizard Installation Mode Screenshot]

  * *Step 0: Download Additional OSCAR Packages [optional]*
    * This step allows additional third-party packages to be downloaded via OPD (OSCAR Package Downloader).  It is possible to enter your own repository information as well.
  * *Step 1: Select OSCAR Packages To Install*
    * This step allows the selection of non-core OSCAR Packages to be installed.  Typically these are resource manager/scheduling systems, parallel programming libraries as well as other tools that aid in cluster administration.  Certain packages may conflict with each other and only allow either one of them to be installed (eg. SGE vs TORQUE/Maui).
  * *Step 2: Configure Selected OSCAR Packages*
    * Certain packages have configuration options that can be set prior to installation, these settings can be set during this step.
  * *Step 3: Install OSCAR Server Packages*
    * This step would install all the selected packages (in Step 1) on the server (headnode) - this step is repeatable.
  * *Step 4: Build OSCAR Client Image*
    * This step allows the user to build an OS image using SystemInstaller.  This image will then be pushed to the compute nodes as part of cluster installation.
  * *Step 5: Define OSCAR Clients*
    * After image(s) are created, clients to be part of your cluster needs to be defined.  The user can select hostnames for your compute nodes, number of nodes, etc.
  * *Step 6: Setup Networking*
    * This step allows the user to tie MAC addresses to defined clients (in the previous step) such that when they boot up, they will automatically be imaged.  Installation mode is also set in this step - currently available modes are: systemimager-rsync (default), systemimager-multicast, systemimager-bt.  After this mode is set, the user should then configure DHCP Server and also select Setup Network Boot.
  * *Delete OSCAR Clients*
    * This button allows the user to delete OSCAR clients from the cluster.  Services will be stopped on the nodes to be deleted and restarted on all the remaining nodes.  The cluster will be re-configured without the presence of the deleted node entries in ODA. 
  * *Monitor Cluster Deployment*
    * This step brings up the SystemImager monitoring widget `si_monitortk` which provides very useful information regarding image progress.  The user can also invoke the Virtual Console by double-clicking on a node and this will bring up a window with console messages during the installation.
  * *Step 7: Complete Cluster Setup*
    * Perform this step after all your cluster nodes have successfully been imaged and rebooted.  This step will initiate post-cluster installation fix-ups and get it ready for production.
  * *Step 8: Test Cluster Setup [optional]*
    * OSCAR provides some tests for its packages and this step invokes all these testing harness to ensure that your cluster is setup properly and ready for production runs. 

## Management Mode

This mode is invoked via `scripts/oscar_wizard manage` and contains buttons for interacting with your cluster after it has been deployed initially:

[attachment:oscar_wizard_manage.png OSCAR Wizard Management Mode Screenshot]

  * *Download Additional OSCAR Packages*
    * [Same as for Installation mode, see above]
  * *Build OSCAR Client Image*
    * [Same as for Installation mode, see above]
  * *Manage OSCAR Clients*
    * This button allows the user to add new clients to the OSCAR cluster after it has been initially deployed.  It contains three additional steps from the Installation mode: Define OSCAR Clients, Setup Networking and Complete Cluster Setup.
  * *Delete OSCAR Clients*
    * [Same as for Installation mode, see above]
  * *Install/Uninstall OSCAR Packages*
    * This button allows the use to install or uninstall OSCAR Packages after initial deployment.
  * *Monitor Cluster Deployment*
    * [Same as for Installation mode, see above]
  * *Test Cluster Setup*
    * [Same as for Installation mode, see above]
  * *Network Boot Manager*
    * This button invokes the Network Boot Manager `netbootmgr` which allows the user to control boot preferences of nodes.  Each node needs to be booting off the network for this to work, this typically involves changing the BIOS option to boot network first (or at least before local HD).  Boot action include Install (network install), Localboot (boot from HD), Memtest (run memtest on node), etc.
  * *Ganglia Monitoring System*
    * If Ganglia is installed on the system, then this button will be present in the Management mode of the OSCAR Wizard.  This simply brings up your favourite web browser (Firefox by default) and open the Ganglia Monitoring page (!http://localhost/ganglia).
