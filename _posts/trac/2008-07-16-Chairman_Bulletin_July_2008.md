---
layout: blog
title: Monthly Chairman Bulletin - July 2008
meta: Monthly Chairman Bulletin - July 2008
category: trac
folder: trac
---
<!-- Name: Chairman_Bulletin_July_2008 -->
<!-- Version: 1 -->
<!-- Last-Modified: 2008/07/16 16:01:22 -->
<!-- Author: valleegr -->

System-level virtualization is today widely used for server consolidation and even if the benefits of system-level virtualization for High Performance Computing is still very unclear, one may argue that a management software such as OSCAR should support virtualization.
What is the current support for virtualization in OSCAR? Is it possible to deploy VMWare or Xen virtual machines with OSCAR and to monitor them remotely?
A team at ORNL was actually working on that issue and the OSCAR-V project (http://www.csm.ornl.gov/srt/oscarv.html) was initiated. This project is based on a modified version of OSCAR in order to support both the management of the HostOSes (the systems that host the virtual machines) and the virtual machines. Unfortunately, these modifications were very important making their port directly into OSCAR very difficult. To address this issue, we have been working on the extension of OSCAR during the past few months: mainly the support of the concept of cluster's partitions and the implementation of a new GUI which is simpler to extend and maintain.
Based on this work, we are close to enable the following scenario: the system administrator defines a partition of the system for the creation of HostOSes, which means that the virtualization solution (for instance Xen or QEMU) is installed on those systems. When the HostOSes are finally deployed by OSCAR, it is then possible to deploy virtual machines: the system administrator creates a virtual partition, defines it (what is the Linux distribution? What software should be installed?), and then can deploy it.
The features are still under development and we do not plan to release those before OSCAR-5.4. But the new GUI is under active development and trunk should support soon the definition and the deployment of partition. More details very soon!