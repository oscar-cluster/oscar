---
layout: wiki
title: InstallGuideIntroduction
meta: 
permalink: "wiki/InstallGuideIntroduction"
category: wiki
---
<!-- Name: InstallGuideIntroduction -->
<!-- Version: 29 -->
<!-- Author: olahaye74 -->

[[TOC]]

[back to Table of Contents](wiki/InstallGuide)

# Chapter 1: Introduction

== 1.1 Overview == #Overview

OSCAR version 6.1 is a snapshot of the best known methods for building, programming,
and using clusters. It consists of a fully integrated and easy to install software bundle designed
for high performance computing (HPC) cluster. Everything needed to install, build, maintain, and use a Linux cluster is included in the suite.

OSCAR is the primary project of the Open Cluster Group. For more information on the group and its
projects, visit its website [http://www.openclustergroup.org/].

This document provides a step-by-step installation guide for system administrators, as well as a detailed explanation of what is happening as installation progresses.

Please be sure that you have the latest version of this document. The PDF version of this document which is included in the distribution is a snapshot of the OSCAR Trac wiki [http://svn.oscar.openclustergroup.org/trac/oscar/wiki] which may have been updated since this version was released.


== 1.2 Terminology == #Terminology

A common term used in this document is cluster, which refers to a group of individual computers bundled
together using hardware and software in order to make them work as a single machine.
Each individual machine of a cluster is referred to as a node. Within the OSCAR cluster to be installed, there are two types of nodes: server and client. A server node is responsible for servicing the requests of client nodes. A client node is dedicated to computation.

It is possible to create clusters with only one type of processor and operating system (called a homogeneous cluster) or with more than one type of processor or operating system (called a heterogeneous cluster). 

An OSCAR package is a set of files that is used to install a software package in an OSCAR cluster. An
OSCAR package can be as simple as a single binary file, or it can be more complex, perhaps including a
mixture of binary and other auxiliary configuration / installation files. OSCAR packages provide the majority of functionality in OSCAR clusters.

OSCAR packages fall into one of three categories:
 * Core packages are required for the operation of OSCAR itself (mostly involved with the installer).
 * Included packages are shipped in the official OSCAR distribution. These are usually authored and/or packaged by OSCAR developers, and have some degree of official testing before release.
 * Third party packages are not included in the official OSCAR distribution; they are _add-ons_ that can be unpacked in the OSCAR tree, and therefore installed using the OSCAR installation framework.

== 1.3: Overview of System Installation Suite (SIS) == #SIS

The System Installation Suite (SIS) is a cluster installation tool developed by the collaboration of the IBM Linux Technology Center and the SystemImager team. SIS was chosen to be the installation mechanism for OSCAR for multiple reasons:

 * SIS is a high-quality, third party, open source product that works well in production environments
 * SIS does not require the client nodes to already have Linux installed
 * SIS maintains a database containing installation and configuration information about each node in the cluster

In order to understand some of the steps in the upcoming install, you will need knowledge of the main concepts used within SIS. The first concept is that of an image. In SIS, an image is defined for use by the cluster nodes. This image is a copy of the operating system files stored on the server. The client nodes install by replicating this image to their local disk partitions. Another important concept from SIS is the client definition. A SIS client is defined for each of your cluster nodes. These client definitions keep track of the pertinent information about each client. The server node is responsible for creating the cluster information database and for servicing client installation requests. The information that is stored for each client includes:

 * IP information such as hostname, IP address, route.
 * Image name.

Each of these pieces of information will be discussed further as part of the detailed install procedure.

For additional information on the concepts in SIS and how to use it, you should refer to the SIS(1) man page. In addition, you can visit the SIS web site at [http://wiki.systemimager.org/] for recent updates.

== 1.4 Supported Distributions == #SupportedDistributions
This version of OSCAR has been tested to work with a single Linux distribution. It is, however, known to have certain compatibility issues with some of the distributions. The suggested workarounds in such cases have been discussed in this document. Table 1 lists each distribution and version and
specifies the level of support for each. In order to ensure a successful installation, most users should stick to a distribution that is listed as Fully supported.


    #!html
    <table border="1" cellpadding="10">
     <caption>Table 1: OSCAR Supported Distributions</caption>
     <tr>
      <th>Distribution and Release</th>
      <th>Architecture</th>
      <th>Status</th>
      <th>Known Issues</th>
     </tr>
     <tr>
      <td>Red Hat Enterprise Linux 7 / CentOS 7</td><td>x86_64</td><td>WIP</td><td>No SystemImager package</td>
     </tr>
     <tr>
      <td>Red Hat Enterprise Linux 6 / CentOS 6</td><td>x86_64</td><td>Fully supported</td><td>None</td>
     </tr>
     <tr>
      <td>Red Hat Enterprise Linux 5 / CentOS 5</td><td>x86</td><td>Not supported</td><td>None</td>
     </tr>
     <tr>
      <td>Red Hat Enterprise Linux 5 / CentOS 5</td><td>x86_64</td><td>Not supported</td><td>None</td>
     </tr>
     <tr>
      <td>Fedora Core 20</td><td>x86_64</td><td>WIP</td><td>Not all OSCAR packages are supported, no SystemImager package</td>
     </tr>
     <tr>
      <td>Fedora Core 19</td><td>x86_64</td><td>WIP</td><td>Not all OSCAR packages are supported, no SystemImager package</td>
     </tr>
     <tr>
      <td>Fedora Core 18</td><td>x86_64</td><td>WIP</td><td>Not all OSCAR packages are supported, no SystemImager package</td>
     </tr>
     <tr>
      <td>Fedora Core 17</td><td>x86_64</td><td>WIP</td><td>Not all OSCAR packages are supported</td>
     </tr>
     <tr>
      <td>Debian 7</td><td>x86_64</td><td>Fully supported</td><td>Not all OSCAR packages are supported</td>
     </tr>
     <tr>
      <td>Debian 6</td><td>x86_64</td><td>Fully supported</td><td>Not all OSCAR packages are supported</td>
     </tr>
     <tr>
      <td>Debian 5</td><td>x86_64</td><td>Fully supported</td><td>Not all OSCAR packages are supported</td>
     </tr>
     <tr>
      <td>Ubuntu 13.04 (LTS)</td><td>x86_64</td><td>Fully supported</td><td>Not all OSCAR packages are supported</td>
     </tr>
     <tr>
      <td>Ubuntu 12.10</td><td>x86_64</td><td>Fully supported</td><td>Not all OSCAR packages are supported</td>
     </tr>
     <tr>
      <td>Ubuntu 12.04 (LTS)</td><td>x86_64</td><td>Fully supported</td><td>Not all OSCAR packages are supported</td>
     </tr>
     <tr>
      <td>Ubuntu 10.04 (LTS)</td><td>x86_64</td><td>Not supported</td><td>Not all OSCAR packages are supported</td>
     </tr>
    <table>

[[BR]]

Clones of supported distributions, especially open source rebuilds of Red Hat Enterprise Linux such as
CentOS and Scientific Linux, should work but are not officially tested. See the release notes (Section 3) for your distribution for known issues.

== 1.5 Minimum System Requirements == #SystemRequirements

The following is a list of minimum system requirements for the OSCAR server node:

 * CPU of i586 or above
 * A network interface card that supports a TCP/IP stack
 * If your OSCAR server node is going to be the router between a public network and the cluster nodes, you will need a second network interface card that supports a TCP/IP stack
 * At least 30GB total free space – 20GB under / and 10GB under /var
 * An installed version of Linux, preferably a Fully supported distribution from Table 1 The following is a list of minimum system requirements for the OSCAR client nodes:

The following is a list of minimum system requirements for the OSCAR compute node:

 * CPU of i586 or above
 * A disk on each client node, at least 20GB in size (OSCAR will format the disks during the installation)
 * A network interface card that supports a TCP/IP stack
 * CD-ROM drive or PXE enabled BIOS on the client nodes

Monitors and keyboards are helpful, but are not required.

Given the wide variety of software and hardware combinations possible in a compute clusters, it is impossible for us to keep an accurate list of hardware which OSCAR supports. If the hardware works on a stock install of the host operating system, there are fair odds that it will not cause any problems with OSCAR.

== 1.6 Document Organization == #DocumentOrganization

Due to the complicated nature of putting together a high-performance cluster, it is strongly suggested that even experienced system administrators read this document through, without skipping any sections, and then use the detailed installation procedure to install your OSCAR cluster. Novice users will be comforted to know that anyone who has installed and used Linux can successfully navigate through the OSCAR cluster install.

The rest of this document is organized as follows. First, [Section 2](wiki/InstallGuideReleaseNotes) tells how to install OSCAR on your system. Next, the [Release Notes section (Section 3)](wiki/InstallGuideReleaseNotes) that applies to this OSCAR version contains some requirements and update issues that need to be resolved before the install. Section 4 provides an overview for the System Installation Suite software package used in OSCAR to perform the bulk of the cluster installation. Section 5 details the cluster installation procedure (the level of detail lies somewhere between "the install will now update some files" and "the install will now replace the string ‘xyz’ with ‘abc’ in file some file.") Finally, Section 6 contains system administration notes about several of the individual packages that are installed by OSCAR. This section is a _must read_ for all OSCAR system administrators.

Appendix A covers the topic of network booting client nodes, which is so important that it deserved its own section. Appendix B provides curious users an overview of what really happens during a client install. Appendix C discusses how to install an OSCAR cluster without a DHCP server. Appendix D covers a primer of some security aspects of a Linux cluster. Although not intended to be a comprehensive description of cluster security, it is a good overview for those who know relatively little about system administration and security. Finally, Appendix E is a screen-by-screen walk through of a typical OSCAR installation.

If you have a question that cannot be answered by this document (including answers to common installation problems), be sure to visit the [OSCAR web site](http://oscar.sourceforge.net) or the [mailing list archives](http://sourceforge.net/mail/?group_id=9368).  The OSCAR mailing lists only accept posts from members of the lists so please join the list before posting a message.  This helps to keep our lists spam free.

