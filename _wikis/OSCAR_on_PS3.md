---
layout: wiki
title: OSCAR_on_PS3
meta: 
permalink: "/wiki/OSCAR_on_PS3"
category: wiki
---
<!-- Name: OSCAR_on_PS3 -->
<!-- Version: 6 -->
<!-- Author: dikim -->

## Installing OSCAR on Playstation 3

This documentation is based on the following requirements but I believe that it won't be too difficult to try this on a different distro or different version of OSCAR. Please let me know if you are interested in testing this on the different distro and encounter any problems.

### Requirements
    * [http://oscar.openclustergroup.org/filebrowser/49/crispy:OSCAR 5.1 Crispy branch]
    * 2 x PS3 machines or more
    * USB key
    * [http://svn.oscar.openclustergroup.org/trac/oscar/attachment/wiki/OSCAR_on_PS3/otheros.bld?format=raw: OtherOS Installer]
    * HDMI-DVI connector
    * [http://www.terrasoftsolutions.com/resources/downloads.shtml: YellowDogLinux(YDL)5.0 (PPC) DVD] (This is my choice to make it easy to build PPC linux packages but I believe that any recent linux distro would work fine with my instruction)
    * USB Keyboard and USB mouse
    * Network

### Install
#### Step 1. Install Linux on PS3
    * Download the [http://svn.oscar.openclustergroup.org/trac/oscar/attachment/wiki/OSCAR_on_PS3/otheros.bld?format=raw: OtherOS installer] specially built for OSCAR
    * Save it to the USB key (FAT format) and then hook it up to the PS3
       * On your USB key, create a directory /PS3/otheros and then copy the downloaded the otheros.bld file to /PS3/otheros/

    mkdir -p /PS3/otheros
    cp otheros.bld /PS3/otheros/

    * Power on PS3 on the game mode
       * Settings Menu → System Settings → A partition setting for hard disk: custom
          * 60GB = 10GB(Game) + 50GB(Linux)
       * Settings Menu → System Settings → Install Other OS
          * Click on OK to start the installation
       * Settings → System Settings → Default System and select “Other OS”

    * Insert YDL5.0 DVD
    * Restart PS3 to boot with Other OS
    * Type in “install” at the kboot prompt
    * Do the YDL5.0 installation

#### Step 2. Install OSCAR
    * Once YDL5.0 is fully installed and up, download [http://oscar.openclustergroup.org/filebrowser/49/crispy:OSCAR 5.1 crispy branch]
    * Follow the ordinary OSCAR installation instruction
      * After oscarimage is created at the oscar installation Step 4, there is one thing to modify the image manually. Just remove the systemconfig.conf file at the oscarimage built
      * At the OSCAR installation step 6. “Setup Networking…”, prepare PS3 client nodes to boot up with OtherOS like we did it on the head node PS3 at the above Step 1.

            chroot /var/lib/systemimager/images/oscarimage
            cd /etc/systemconfig
            mv systemconfig.conf systemconfig.conf.bak       
    * Finish up the OSCAR installation

### Acknowledgments
    * Andrew Lumsdaine (OSL, Indiana University)
    * Bernard Li (bernard _at_ vanhpc _dot_ org)
    * David Lombard (Intel)
