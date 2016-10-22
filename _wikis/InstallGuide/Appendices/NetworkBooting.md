---
layout: wiki
title: InstallGuide/Appendices/NetworkBooting
meta: 
permalink: "/wiki/InstallGuide/Appendices/NetworkBooting"
category: wiki
folder: wiki
---
<!-- Name: InstallGuide/Appendices/NetworkBooting -->
<!-- Version: 2 -->
<!-- Author: olahaye74 -->
[back to Table of Contents](/wiki/InstallGuide/)

# Appendix A: Network Booting Client Nodes

There are two methods available for network booting your client nodes. The first is to use the Preboot eXecution Environment (PXE) network boot option in the client’s BIOS, if available. If the option is not available, you will need to create a network boot CD disk using the SystemImager boot package or use an Etherboot disk. Each method is described below.

 1. Network booting using PXE. To use this method, the BIOS and network adapter on each of the client nodes will need to support PXE version 2.0 or later. The PXE specification is available at [http://developer.intel.com/ial/wfm/tools/pxepdk20/]. Earlier versions may work, but experience has shown that versions earlier than 2.0 are unreliable. As BIOS designs vary, there is not a standard procedure for network booting client nodes using PXE. More often than not, the option is presented in one of two ways.
 1. The first is that the option can be specified in the BIOS boot order list. If presented in the boot order list, you will need to set the client to have network boot as the first boot device. <del>In addition, when you have completed the client installation, remember to reset the BIOS and remove network boot from the boot list so that the client will boot from its local hard drive and will not attempt to do the installation again.</del> The net boot manager records when the client node has been imaged, and will cause the client to boot from its own hard drive. If you replace the hard drive or require it to be reimaged, use the oscar_wizard Net Boot Manager menu.
 1. The second is that the user must watch the output of the client node while booting and press a specified key such as "F12" or "N" at the appropriate time. In this case, you will need to do so for each client as it boots.
 1. Network booting using a SystemImager boot CD. The SystemImager boot package is provided with OSCAR just in case your machines do not have a BIOS network boot option. You can create a boot CD through the OSCAR GUI installation wizard on the <Setup Networking> panel or by using the mkautoinstallCD command. Once you have created the SystemImager boot CD, set your client’s BIOS to boot from the CD drive. Insert the CD and boot the machine to start the network boot. Check the output for errors to make sure your network boot CD is working properly. Remember to remove the CD when you reboot the clients after installation.
 1. Using an Etherboot disk Etherboot is a software package for creating ROM images. This type of image is what drives the PXE network boot process described above. However, the Etherboot package ([http://www.etherboot.org/]) can also be used to create bootable flopy diskettes that mimic the PXE functionality of many network cards. This is useful for both older systems, and because booting off a diskette is sometimes easier than fiddling around with BIOS settings. A users manual with installation instructions can be found on the project’s website ([http://www.etherboot.org/]). This tool is not supported by the OSCAR team directly, but is very handy.