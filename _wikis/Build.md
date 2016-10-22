---
layout: wiki
title: Build
meta: 
permalink: "/wiki/Build"
category: wiki
---
<!-- Name: Build -->
<!-- Version: 7 -->
<!-- Author: wesbland -->

[Development Documentation](/wiki/DevelDocs/) > [Command Line Interface](/wiki/CLI/) > Build Client Image

# Build Client Image

This step is required.

This step will build the Image for the OSCAR clients.

## Interactive Version

The interactive version of this file will provide a menu after a short preparation section.  The menu will look like this:


    Select one
    -----------------------------------------
    1) Image name: oscarimage
    2) Package file: /tmp/oscar-trunk//oscarsamples/fc-4-i386.rpmlist
    3) Distro: fedora-4-i386
    4) Package Repositories: /tftpboot/oscar/common-rpms,/tftpboot/oscar/fc-4-i386,/tftpboot/distro/fedora-4-i386
    5) Disk Partition File: /opt/oscar/oscarsamples/scsi.disk
    6) IP Assignment Method: static
    7) Post install action: beep
    8) Build Image
    9) Quit
    >

The values will be dynamically filled in based on the defaults for the OSCAR install.  After the user makes a selection from the list, a prompt will come up to get a new value from the user.

Once the user picks Build Image, the image will be built.  As the user inputs the selections, they will be dumped to a log file called build.log that can be later used as input for the non-interactive mode to recreate the current install.

## Non-Interactive Version

To access the non-interactive version, use the flag `--filename` or `-f` followed by the filename to be used.  This file should simply have the input that would be typed in on the command line if the program were run in interactive mode.  Each selection number and piece of data should be seperated by a newline.  

For example:


    1
    testcluster
    7
    reboot
    8

This would set the image name to be testcluster, set the post install action to be reboot, and would then start the build process.  The 8 at the end will signify the end of the file and the build process.