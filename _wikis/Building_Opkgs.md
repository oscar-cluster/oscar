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
[Documentations](Document) > [Developer Documentations](DevelDocs) > Build OSCAR Packages

## Build OSCAR meta packages

*WARNING, this is only for developping a new opkg. To package OSCAR already existing opkgs, please use oscar-packager*

### Reqirements
  * installed version of opkgc (either on a running OSCAR system or in a docker container
     (see [Distro Support](DistroSupport) on how to bootstrap a oscar development container)

### How to build Opkg meta rpms via opkgc
This example is tested on RHEL7.[[BR]]
My $OSCAR_WORKING_COPY is where I checked out the package git repository.
  * Build opkgs of OSCAR packages one by one 

        cd $OSCAR_WORKING_COPY
        sudo opkgc --dist=rhel --input=./opkg --output=/path/to/local/distro/packages/
    where --dist=rhel does not have the distro version number(e.g., 7).
    The built opkg rpms are created in output destination (localdir if not specified).
    
  * Build opkgs of all the OSCAR packages at once

        for repo in $(curl -s "https://api.github.com/users/oscar-cluster/repos?per_page=1000" | grep -w clone_url | grep -o '[^"]\+://.\+.git'|grep -Ev 'pkgsrc|tags')
        do
          git clone --depth=1 $repo work
          cd work
          opkgc --dist=rhel --input=./opkg --output=/path/to/local/distro/packages/
          cd ..
          /bin/rm -rf work
        done

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
