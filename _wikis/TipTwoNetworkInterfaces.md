---
layout: wiki
title: TipTwoNetworkInterfaces
meta: 
permalink: "wiki/TipTwoNetworkInterfaces"
category: wiki
---
<!-- Name: TipTwoNetworkInterfaces -->
<!-- Version: 4 -->
<!-- Author: mledward -->

# Using Two Network Interfaces with OSCAR

These instructions are designed to be some guidance on how to use dual network card setups with OSCAR.  The main documentation assumes a single network interface is being used for the cluster, the same one for both the head and compute nodes.  In many cases it is desirable to use at least two network interfaces on the head node.

This example makes the head node into a true gateway, with one interface (eth0) which is purely internal and one interface (eth1) which is purely external.

This was developed and tested on OSCAR 5.0 on a 30 node cluster of Dell PE1950's using RedHat Enterprise Linux AS 4 Update 4.  Your mileage may vary.  I have tried to remove the pieces which are specific to that hardware.

 * Install RHEL 4 - Add development tools at least, and graphical internet
 * Install OSCAR as described here [wiki/InstallGuide]
 * fix `/etc/hosts` so the localhost and hostname are in different lines.  hostname and public interface IP should be together.  Use a fake name for internal IP


    127.0.0.1 localhost.localdomain localdomain
    123.456.789.101 mycluster.myschool.edu mycluster
    10.0.0.1 head.oscardomain.edu head

This puts the address 123.456.789.101 (which should be changed to fit your local network) together with the real hostname mycluster.myschool.edu.  This is the interface which will be connected to your public network.  The internal interface is associated with the "fake" name head.oscardomain.edu and should be the interface with which you setup Oscar.  I generally call the internal interface eth0 and the external interface eth1 in order to keep the interface name the same on the head and compute nodes.  

