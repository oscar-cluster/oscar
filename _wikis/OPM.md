---
layout: wiki
title: OPM
meta: 
permalink: "wiki/OPM"
category: wiki
---
<!-- Name: OPM -->
<!-- Version: 11 -->
<!-- Author: wesbland -->

[Development Documentation](wiki/DevelDocs) > OSCAR Package Manager

# OSCAR Package Manager (OPM)

The OSCAR Package Manger is a mechanism to install OSCAR packages in the new format (see [../browser/pkgsrc/opkgc/trunk/doc/opkg.5.html?format=raw opkg]).  It performs tasks based on a request system in the OSCAR database (ODA).  When OPM is started, it will walk through the database, looking at every package on every node, and see what needs to be done for that package.  The request field in the database will state what step of the install/uninstall process the package should be at and OPM will perform the steps necessary to get it to that stage.  See the Stages section for more details about each stage.  OPM will run on the headnode as well as all the compute nodes.  This will mean that once the cluster has been initially set up, the nodes will be responsible for maintaining themselves.

There are differences in the server and client versions of OPM.  The server will run all the steps while the client will only run the install-bpkg step.  The server will get its work from some other tool while the clients will get their work from the server.

(See also: [OSCAR Package API](wiki/opkgAPI))

## /etc/opm.conf

OPM will have a file called `/etc/opm.conf` which will hold the type of the machine OPM is running on (server/client/image) and the name of the machine or image.  An example of the file would be:


    client
    oscarnode1

or:


    image
    oscarimage

This is important to know when running OPM because of the differences in what OPM does based on whether it is running on a server or client or image.  It also makes finding the hostname of the node/image much more reliable than trying to use the `hostname` command.

## Rules

This is what OPM does each time it runs:

 * Checks the database for work
 * If it finds some work, it does it according to rules:
   1. Checks `status` to see if it says `error`
     * If so, there is an error and OPM will skip this package until the error is resolved
   1. Checks if `request` is different from `current`
     * If so, it needs to perform the steps to get it to `request`

Some other tool is responsible for calling OPM.
Some other tool is responsible for giving the work to OPM (possibly the same tool that calls it).

## Stages

This section describes what OPM will do at each stage.  If the package is currently at `setup_phase` and the database has a request for the `post-bpkg-install_phase`, OPM will perform everything in `pre-configure`, `post-configure`, and `post-bpkg-install` phases.  This is not true if the initial OSCAR installation has not progressed to the correct point.  The notes in the square brackets denote what stage the OSCAR install needs to be at for the OPM step to be run.

 1. `should_be_installed` [setup-wizard]
   * Install opkg-<package>
     * Runs api-pre-install
     * Runs api-post-install
   * Unpacks other scripts
 1. `run-configurator` [setup-wizard]
   * Runs api-pre-configure
   * Perform any configuration necessary
   * Runs api-post-configure
 1. `install-bin-pkgs` [build_image]
   * Install opkg-<package>-server/client
   * Runs native scripts
   * Installs <package>  as well
 1. `post-image` [addclients]
   * Runs api-post-image
 1. `post-clients` [post_install]
   * Runs api-post-clients
   * Assign work to clients
 1. `post-install` [test_install]
   * Runs api-post-deploy
