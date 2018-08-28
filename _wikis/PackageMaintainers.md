---
layout: wiki
title: PackageMaintainers
meta: 
permalink: "wiki/PackageMaintainers"
category: wiki
---
<!-- Name: PackageMaintainers -->
<!-- Version: 8 -->
<!-- Author: dikim -->
[Contact](Contact) 

## OSCAR Package Maintainers

The following is a list of OSCAR packages and their respective maintainers.  The maintainer's responsibility is to update the software on a regular basis and resolve any known building/operating issues on the various architecture platforms that OSCAR supports (namely x86, x86_64 and ia64):

| *OSCAR Package* | *Maintainer* | *Description*
| --- | --- |
| APITest             | Thomas Naughton, Olivier Lahaye  | Cluster installation test engine
| BLCR                | (obsolete)                       | Berkley Checkpoint Restart.
| C3                  | Thomas Naughton, Olivier Lahaye  | Tool to run a command across compute nodes
| Configurator        | Olivier Lahaye                   |
| Env-switcher        | DongInn Kim                      | module to switch across different MPI stacks
| Ganglia             | Erich Focht, Olivier Lahaye      | Cluster web medtrics (load, jobs, ...)
| Jobmonarch          | Olivier Lahaye                   | Cluster web job history listing (ganglia module)
| Kernel-picker       | Olivier Lahaye                   |
| LAM/MPI             | Not supported anymore            | Old MPI stack
| Loghost             | Olivier Lahaye                   | Configure head as syslog host (accept nodes logs)
| MPICH               | Erich Focht                      | an MPI stack
| Maui                | DongInn Kim, Olivier Lahaye      | Smart job scheduler (mainly used with torque)
| Naemon              | Olivier Lahaye                   | Cluster health monitoring with web interface
| NetBootMgr          | Erich Focht                      | GUI to set node next PXE boot menu
| Network-configurator| Olivier Lahaye                   | Part of OSCAR API
| ODA                 | DongInn Kim                      | Oscar Database API
| Open MPI            | DongInn Kim                      | an MPI stack
| Opium               | Olivier Lahaye                   | SSH configuration for nodes
| Opkgc               | Olivier Lahaye                   | Oscar opkg distro package generator "compiler" (used by oscar-packager)
| Orm                 | Olivier Lahaye                   | Oscar Repository Managfer
| Oscar               | Olivier Lahaye                   | Main OSCAR component
| Oscar-installer     |                                  | OSCAR offline install program from tarballs (obsolete)
| Oscar-nat           | Thomas Naughto                   | Manage OSCAR NAT tables. (currently broken)
| Oscar-packager      | Olivier Lahaye                   | Main OSCAR distro package builder.
| PVM                 | Thomas Naughton, Olivier Lahaye  | 
| Packman             | Olivier Lahaye                   | Package manager (abstraction layer over rpm/deb)
| Pfilter             | broken?                          | iptable configuration
| Rapt                | Olivier Lahaye                   | enhanced apt to deal with local oscar repositories (similar to yume for rpms)
| SC3                 | Erich Focht, Olivier Lahaye      | enhanced C3 that can deal with subclusters.
| SGE                 |                                  | Sun Grid Engine. currently broken.
| SIS : systemiconfigurator | Olivier Lahaye, Erich Focht| Used to configure kernel+bootloader+network on imaged nodes. Now obsolete and only kept for perle API dependancies.
| SIS : systemimager        | Olivier Lahaye             | Client/Server software used to deploy nodes thru PXE.
| SIS : systeminstaller     | Olivier Lahaye, Erich Focht| Set of scripts to create and configure images for systemimager.
| Selector            | Olivier Lahaye                   | OSCAR components selection GUI
| Slurm               | Olivier Lahaye                   | Modern job queue manager and scheduler with accounting.
| Sync_files          | Olivier Lahaye                   | cron scripts to keep files in sync across compute nodes.
| System-update       | Olivier Lahaye                   | Manage OS updates across cluster
| TORQUE              | Olivier Lahaye                   | job batch queue manager (includes a primitive scheduler that is best replaced with Maui)
| Yume                |                                  | Yum enhanced able to deal with oscar local repos (similar to rapt for debs)
