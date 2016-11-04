---
layout: wiki
title: InstallGuide/Appendices/SISBoot
meta: 
permalink: "wiki/InstallGuide/Appendices/SISBoot"
category: wiki
folder: wiki
---
<!-- Name: InstallGuide/Appendices/SISBoot -->
<!-- Version: 1 -->
<!-- Author: jparpail -->
[back to Table of Contents](wiki/InstallGuide)

# Appendix B: What Happens During Client Installation

Once the client is network booted, it either boots off the autoinstall CD that you created or uses PXE to network boot, and loads the install kernel. It then broadcasts a BOOTP/DHCP request to obtain the IP address associated with its MAC address. The DHCP server provides the IP information and the client looks for its auto-install script in `/var/lib/systemimager/scripts/`. The script is named <nodename>.sh and is a symbolic link to the script for the desired image. The auto-install script is the installation workhorse, and does the following:
 1. partitions the disk as specified in the image in <imagedir>/etc/systemimager/partitionschemes.
 1. mounts the newly created partitions on /a.
 1. chroots to /a and uses rsync to bring over all the files in the image.
 1. invokes systemconfigurator to customize the image to the client’s particular hardware and configuration.
 1. unmounts /a.

Once clone completes, the client will either reboot, halt, or beep as specified when defining the image.
