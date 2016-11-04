---
layout: wiki
title: Building_Opkgs
meta: 
permalink: "wiki/Building_Opkgs"
category: wiki
---
<!-- Name: Building_Opkgs -->
<!-- Version: 10 -->
<!-- Author: valleegr -->

## Build OSCAR meta packages

*WARNING, this will work ONLY on RPM based systems and for OSCAR 5.x and previous version. It will not work for OSCAR-6.x and later version. To package OSCAR-6.x, please use oscar-packager*

### Reqirements
  * python 2.4 or newer version
  * python-cheetah
  * python-lxml
  * opkgc trunk

### How to get a working opkgc
  * Check out trunk of the opkgc repository

        svn co https://svn.oscar.openclustergroup.org/svn/oscar/pkgsrc/opkgc/trunk opkgc
  * Make opkgc

        cd opkgc
        ./autogen.sh
        ./configure && make
        sudo make install
  * Add Opkgc to your PYTHONPATH
    * setup the following PYTHONPATH to your shell rc file for a permanent configuration

        export PYTHONPATH=$PYTHONPATH:/usr/local/lib/python2.4/site-packages 
    * Or make a symlink to the standard python lib

        ln -s /usr/local/lib/python2.4/site-packages/Opkgc /usr/lib/python2.4/site-packages/Opkgc


### How to build Opkg meta rpms via opkgc
This example is tested on RHEL5 X86.[[BR]]
My $OSCAR_WORKING_COPY is where I checked out the OSCAR subversion repository.
  * Build opkgs of OSCAR packages one by one 

        cd $OSCAR_WORKING_COPY/packages
        sudo opkgc --dist=rhel --input=./openmpi
    where --dist=rhel does not have the distro version number(e.g., 5).
    The built opkg rpms are created on /usr/src/redhat/RPMS/noarch.
  * Build opkgs of all the OSCAR packages at once

        cd $OSCAR_WORKING_COPY
        cd packages; env OSCAR_HOME=`pwd`/.. ../scripts/build_opkg_rpms `ls -1F | grep '/$'`
    All the built opkg rpms are saved to the distro directory of the corresponding packages. (e.g., opkg rpms for openmpi on RHEL5-X86 are saved at $OSCAR_WORKING_COPY/packages/openmpi/distro/rhel5-i386)

### How to update the change logs in config.xml
The config.xml file of each OSCAR package is the most important factor to build the opkg meta rpms via opkgc. Here is how we want to add the new change logs to the existing config.xml file.
  * Have the exact same version number of the actual OSCAR package
  * Make the release number consistent to the release number of the actual OSCAR package
  * Get your current working timestamp and use it
    ```
    date +%Y-%m-%dT%k:%M:%S%:z
    ```
    or
    ```
    date +%Y-%m-%dT%T%:z
    ```

    This timestamp works fine on bash. In csh or tcsh, you may want to do "date +%Y-%m-%dT%T%z" and then modify the output of the timezone field by adding ":" in the middle.
