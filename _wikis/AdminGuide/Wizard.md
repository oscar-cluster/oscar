---
layout: wiki
title: AdminGuide/Wizard
meta: 
permalink: "/wiki/AdminGuide/Wizard"
category: wiki
folder: wiki
---
<!-- Name: AdminGuide/Wizard -->
<!-- Version: 6 -->
<!-- Author: valleegr -->
[[TOC]]

[back to Table of Contents](/wiki/AdminGuide/)

# Chapter 2: OSCAR Management Wizard

## 2.1 Overview

The OSCAR Management Wizard GUI has the following functionality to allow manipulation of an existing OSCAR cluster:
 * Build a different OSCAR Client image
 * Add new nodes to the cluster
 * Delete nodes from the cluster
 * Test the cluster
 * Reimage or test a node with the Network Boot Manager
 * View the Ganglia Monitoring System

All of the above menu items are optional, and can be executed in any order. However, once started, a choice should be followed through to completion, e.g., after adding new nodes, the Complete Cluster Setup must be done.

If you wish to wipe out the cluster and start over, see the [Starting Over](/wiki/InstallGuideClusterInstall#StartingOver/) section of the [Install Guide](/wiki/InstallGuide/).

## 2.2 Launching the OSCAR Wizard

Once the OSCAR cluster is deployed, start the OSCAR wizard:

    # /usr/bin/oscar_wizard manage

The wizard, as shown in Figure 1, is provided to guide you through the rest of the cluster management. To use the wizard, you will complete a series of steps, 
with each step being initiated by the pressing of a button on the wizard. Do not go on to the next step until the instructions say to do so, 
as there are times when you may need to complete an action outside of the wizard before continuing on with the next step. 
For each step, there is also a <Help> button located directly to the right of the step button. When pressed, 
the <Help> button displays a message box describing the purpose of the step.

*Figure 1: OSCAR Wizard.*

[[Image(figure1_oscar_manage.png)]]


In brief, the functions of the various buttons is as follows:

 * *Build OSCAR Client Image*
   * This step allows the user to build an OS image using SystemInstaller. This image will then be pushed to the compute nodes as part of cluster installation. 
 * *Add OSCAR Clients*
   * Additional clients can be defined in this section.
   * *Step 1: Define OSCAR Clients*
     * The user can select hostnames for your compute nodes, number of nodes, etc.
   * *Step 2: Setup Networking*
     * This step allows the user to tie MAC addresses to defined clients (in the previous step) such that when they boot up, they will automatically be imaged. Installation mode is also set in this step - currently available modes are: systemimager-rsync (default), systemimager-multicast, systemimager-bt. After this mode is set, the user should then configure DHCP Server and also select Setup Network Boot. 
   * *Monitor Cluster Deployment* [optional]
     * This step brings up the SystemImager monitoring widget si_monitortk which provides very useful information regarding image progress. The user can also invoke the Virtual Console by double-clicking on a node and this will bring up a window with console messages during the installation. 
   * *Step 3: Complete Cluster Setup*
     * Perform this step after all your cluster nodes have successfully been imaged and rebooted. This step will initiate post-cluster installation fix-ups and get it ready for production. 
 * *Delete OSCAR Clients*
   * This button allows the user to delete OSCAR clients from the cluster. Services will be stopped on the nodes to be deleted and restarted on all the remaining nodes. The cluster will be re-configured without the presence of the deleted node entries in ODA. 
 * *Install/Uninstall OSCAR Packages*
   * This step allows the selection of non-core OSCAR Packages to be installed or removed. Typically these are resource manager/scheduling systems, parallel programming libraries as well as other tools that aid in cluster administration. Certain packages may conflict with each other and only allow either one of them to be installed (eg. SGE vs TORQUE/Maui).
 * *Test Cluster Setup* [optional]
   * OSCAR provides some tests for its packages and this step invokes all these testing harness to ensure that your cluster is setup properly and ready for production runs. 
 * *Network Boot Manager*
   * This controls what the client does when they boot from the LAN. Choices are: Install, LocalBoot, Kernel-x, and Memtest.
 * *Ganglia Monitoring System*
   * Brings up a webpage showing the status of all the nodes in the cluster.

