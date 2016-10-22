---
layout: wiki
title: Define
meta: 
permalink: "/wiki/Define"
category: wiki
---
<!-- Name: Define -->
<!-- Version: 2 -->
<!-- Author: wesbland -->

[Development Documentation](/wiki/DevelDocs/) > [Command Line Interface](/wiki/CLI/) > Define OSCAR Clients

# Define OSCAR Clients

This step is required.

This step will create the OSCAR clients based on the input provided from the user.

## Interactive Version

The interactive version of this file will provide a menu which will look like this:

    Select one
    -----------------------------------------
    1)  Image Name: oscarimage
    2)  Domain Name: oscardomain
    3)  Base Name: oscarnode
    4)  Number of Hosts: 1
    5)  Starting Number: 1
    6)  Padding: 0
    7)  Starting IP: 192.168.1.1
    8)  Subnet Mask: 255.255.255.0
    9)  Default Gateway: 192.168.1.254
    10) Add Clients
    11) Quit
    >

The values will be dynamically filled in based on the defaults for the OSCAR install.  After the user makes a selection from the list, a prompt will come up to get a new value from the user.  Once the user picks Add Clients, the client images will be assigned.

As the user inputs the selections, they will be dumped to a log file called define.log that can be later used as input for the non-interactive mode to recreate the current install.

## Non-Interactive Version

To access the non-interactive version, use the flag `--filename` or `-f` folowed by the filename to be used.  This file should simply have the input that would be typed in on the command line if the program were run in interactive mode.  Each selection number and piece of data should be seperated by a newline.  

For example:


    1
    imagename
    7
    192.168.1.5
    10

This would set the image name to be imagename, set the starting IP address to be 192.168.1.5, and would then start defining the clients.  The 10 at the end will signify the end of the file.