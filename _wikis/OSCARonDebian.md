---
layout: wiki
title: OSCARonDebian
meta: 
permalink: "wiki/OSCARonDebian"
category: wiki
---
<!-- Name: OSCARonDebian -->
<!-- Version: 5 -->
<!-- Author: valleegr -->

# OSCAR on Debian

## Project Introduction

OSCAR was initially developed for RPM based Linux distributions. Since the OSCAR 4.0 version, the OSCAR architecture allows a simpler port to new Linux distributions which use a different binary package format.

The Debian port is now directly included into OSCAR trunk. All OSCAR packages are not currently supported but OSCAR core and base is almost stable and can be tested (on Etch x86_64 and x86). 
OSCAR on Debian Capabilities:

 * Deployment of Debian Etch x86 and x86_64 clusters.

 * Deployment of RPM based images. In that case, the headnode is based on Etch and compute nodes can be based on any RPM based distribution supported by OSCAR. 

Also note that all OSCAR packages are not yet supported. For more details, see the package page. 

## Software Download

To test the current development version, try the current OSCAR trunk (http://oscar.openclustergroup.org/faq.development.svn-howto). For more information about the port status of OSCAR packages, please click here. News also include some helpfull information. 

## Roadmap

### Creation of a online repository: OSCAR on Debian will be soon available via Debian packages (apt-get install oscar)

This effort is the result of the OPKGC effort (http://oscar.openclustergroup.org/comp_opkgc) that allows us to automatically create binary packages for OSCAR Packages.

Status: Temporary online repositories are now available. They have been created for OSCAR-5.2 which is still under development. If you want to use those repositories, please read the following web page: http://svn.oscar.openclustergroup.org/trac/oscarwiki/trunkTesting. Note that documentation for the use of binary package only is still missing but should be available shortly. 

### Support of images based on different distributions and architectures

All RPM management tools (i.e. rpm, yum, createrepo) are available in Debian Etch and the OSCAR architecture is flexible enough to allow users to create RPM based images on a Debian headnode (e.g. a Centos-4-x86_64 image on a Etch-x86_64 headnode). 

Status: Geoffroy Vallee has checked-in trunk a first prototype that allows one to create RPM based images. Note that the current version of Yum (the underneath tool for the creation of RPM based images) has issues with Python-2.5 which may create problems on some Debian based systems. 

### Automatic testing

In order to speed developments up, a mechanism for automatic testing is currently under development. This mechanism, based on virtualization techniques (e.g. Xen, QEMU), allows one to test OoD with a fresh installation. This is a good solution for not regression test.

Status: a first prototype has been developed by the ORNL team; Geoffroy Vallee is polishing the prototype for diffusion. 
Port of APItest: currently we do not have any Debian package for APItest. 

Status: we contacted the APItest developer in order to find a long term solution. We also created a first Debian package based on the SRPM available in the OSCAR repository. This package still needs to be tested.

## Usefull Links

 * [News - Archive (until December 2008)](wiki/ood_news_archive)

 * [Partners](wiki/ood_partners)

 * [OSCAR Packages Status](wiki/ood_opkg_status)
