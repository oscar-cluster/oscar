---
layout: wiki
title: SetupNetwork
meta: 
permalink: "/wiki/SetupNetwork"
category: wiki
---
<!-- Name: SetupNetwork -->
<!-- Version: 5 -->
<!-- Author: wesbland -->

[Development Documentation](/wiki/DevelDocs/) > [Command Line Interface](/wiki/CLI/) > Setup Network

# Setup Networking

This step is required.

This step will setup the networking between the OSCAR clients and the headnode.

## Interactive Version

The interactive version will of this file will provide a menu which looks like this:


    1)  Import MACs from file:   
    2)  Installation Mode:  systemimager-rsync
    3)  Enable Install Mode
    4)  Dynamic DHCP update:  1
    5)  Configure DHCP Server
    6)  Enable UYOK:  0
    7)  Build AutoInstall CD
    8)  Setup Network Boot
    9)  Finish
    >  

Import MACs from file will prompt the user for a filename.  After the file is read, the user will be asked to either automatically or manually assign the MAC adresses to nodes.

Installation mode is a selectrion of either systemimager-rsync, systemimager-multicast, or systemimager-bt.  The default will work fine here.

Enable Install Mode is required and sets up the previously selected installation mode.

Dynamic DHCP update is like a checkbox.  By selecting this option, the 1 will change to a 0 indicating that the box is no longer checked.

Configure DHCP Server is required and sets up the DHCP server according the the previous selection.

Enable UYOK behaves just like Dynamic DHCP Server.

Build AutoInstall CD will put and iso in /tmp and give directions on how to use it.  This step is optional.

Setup Network Boot will prepare the headnode to network boot the clients.  This step is required.

More than other sections, the steps in this section need to be run in numerical order as the later steps depend on the earlier steps having been completed first.  

## Non-Interactive Version

This version is not yet completed, but will be similar to the other steps where a file will be read in and parsed by the script.