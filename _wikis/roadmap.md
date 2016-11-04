---
layout: wiki
title: roadmap
meta: 
permalink: "wiki/roadmap"
category: wiki
---
<!-- Name: roadmap -->
<!-- Version: 51 -->
<!-- Author: valleegr -->


# Future & Ongoing Work

## OSCAR 6.0.6

  * Ticket #411
  * Ticket #417
  * Ticket #451
  * Ticket #495
  * Ticket #518
  * Ticket #521
  * Ticket #549
  * Ticket #552
  * Ticket #573

## Cluster partitioning

Currently OSCAR only support the Beowulf architecture, architecture that does not really fit with the architecture of modern clusters which are composed on file servers, compute nodes and different other service nodes. The goal of "partitioning effort" is to support such architectures, i.e., support node groups with different software configurations.

## System-level virtualization support

System-level virtualization enables the creation of virtual machines on top of physical machines. This changes the way compute nodes are typically managed: a compute node is not anymore hardware with a single software configuration. Moreover, the usage of system-level virtualization requires the management of virtual machine but also of the "Host OS" which host virtual machine used for application execution.

The official web page of the effort is there: http://www.csm.ornl.gov/srt/oscarv/

# Historic

## OSCAR 6.0.5

*Current status: released on Jan-04, 2010*

The target for OSCAR 6.0.5 is to close the following tickets:

  * Ticket #326
  * Ticket #405
  * Ticket #430
  * Ticket #501
  * Ticket #520
  * Ticket #529
  * Ticket #531
  * Ticket #533
  * Ticket #537
  * Ticket #542
  * Ticket #547
  * Ticket #562
  * Ticket #563
  * Ticket #564
  * Ticket #565
  * Ticket #570
  * Ticket #574
  * Ticket #575

As soon as those bugs will be fixed and when no critical bugs will be reported anymore, OSCAR-6.0.5 will be released.


## OSCAR 6.0.4

*Current status: released on Sept-25, 2009.*

For oscar-6.0.4, the following tickets have be closed:
  * Ticket #134
  * Ticket #314
  * Ticket #364
  * Ticket #466
  * Ticket #486
  * Ticket #504
  * Ticket #546
  * Ticket #532
  * Ticket #380
  * Ticket #548
  * Ticket #551
  * Ticket #553

## OSCAR 6.0.3

*Current status: released on May-27, 2009.*

For oscar-6.0.3, the following tickets have been closed:
  * Ticket #162
  * Ticket #398
  * Ticket #412
  * Ticket #477
  * Ticket #517
  * Ticket #523
  * Ticket #524
  * Ticket #514
  * Ticket #538
  * Ticket #539
  * Ticket #540
  * Ticket #541

Support Fedora Core 9, Debian 5 and Suse 10:
  * 2009/04/30: generation of binary packages for SuSe 10.3 (both openSuSe and SuSe Entreprise Linux) i386 - http://bear.csm.ornl.gov/repos/unstable/sus-10-i386/
  * 2009/04/23: generation of binary packages for Debian 5 x86_64 - http://bear.csm.ornl.gov/repos/unstable/debian-5-x86_64/
  * 2009/04/21: generation of binary packages for Fedora Core 9 i386, update of the online repository (http://bear.csm.ornl.gov/repos/unstable/fc-9-i386).
