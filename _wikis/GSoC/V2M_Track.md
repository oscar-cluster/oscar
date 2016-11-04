---
layout: wiki
title: GSoC/V2M_Track
meta: 
permalink: "wiki/GSoC/V2M_Track"
category: wiki
folder: wiki
---
<!-- Name: GSoC/V2M_Track -->
<!-- Version: 8 -->
<!-- Author: pyzhang -->
# GSoC 2008 V2M Extension Development Track
  Keep a Development Record and progress report for V2M Extension project.
## 2008-06-04
Begin to figure out what Lguest can do and Learn about the Lguest mechanism.
 * What image format Lguest can support?
  * Lguest itself don't provide the image creation tools
   * FAQ provide a decent way: use "dd" command to create a image and use qemu to install the OS, Can Lguest do the installation?
 * What network can lguest support? NAT/Bridge?
Need to Try on the experiment platform.
Plan on the Lguest.cpp and Lguest.h function define.
## 2008-05-25
Almost done the discussion for V2M validation. Need to finish the wiki for project define.
## 2008-05-21
Preparing Lguest building environment, in CentOS 5.1, It make fault with the following Message:
 * "unhandled trap 13 lguest", means page fault error![[maillist track](http://ozlabs.org/pipermail/lguest/2007-August/000219.html|related)]
working on it,
[Solution: some driver made it, recofig and remove some drivers make the lguest works]
 * Lguest64 Just work with Intel Machine. If work for AMD x86_64, Some MSR related error will bring the machine dead(confirmed with Lguest64 developer, and they stop the development currently).
## 2008-05-19
  working on define the milestone and features for V2M extension
