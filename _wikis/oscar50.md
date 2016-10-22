---
layout: wiki
title: oscar50
meta: 
permalink: "/wiki/oscar50"
category: wiki
---
<!-- Name: oscar50 -->
<!-- Version: 2 -->
<!-- Author: jparpail -->

After one year of hard work, debugging, rewriting and testing we are proud to present: *OSCAR 5.0*

 1. Release features
   * [Supported distributions](/wiki/SupportedDistros/)
   * *Completely reworked infrastructure*:
     * smart package managers
     * yum based image build and package install
     * supporting multiple distros on the same cluster
     * repository based
     * easier client updating from repositories
     * simple update path for master, clients, images
     * new package and database structure, prepared for debian support
     * optimized and faster startups
     * new prerequisites handling
     * better pre-installation system configuration checking
     * more flexible OS detection framework
   * modular distribution tarballs, smaller downloads
   * Latest systemimager with many new features:
     * deployment monitoring
     * scalable bittorrent deployment
     * 2.6.18.1 deployment kernel + UYOK (use your own kernel)
   * New and updated packages:
     * Open MPI 1.1.1
     * Maui 3.2.6p14 + Torque 2.0.0p8
     * SGE 6.0u8
     * LAM/MPI 7.1.2
     * MPICH 1.2.7
     * Ganglia 3.0.3
     * SC3: scalable C3 tools with image based addressing.
     * Netbootmgr: manages PXE boot behavior of nodes.
     * sync_files 2.4: handles user databases in heterogeneous clusters.
     * packman 2.8: package manager abstraction. Now uses smart tools like yum(e), (r)apt.
     * systeminstaller-oscar 2.3.1: uses packman abstraction to build images, i.e. yume, rapt, smart package managers.
     * systemconfigurator 2.2.7-12ef: post-install configurator framework. Added tools for selecting boot kernel and manipulating boot options.
   * management panel: single entry point for simple management tasks
   * ...
 1. Quick install guide

    To get installation tarballs, see [wiki/Download Download page].
    * '''The OSCAR distribution''' comes in two OSCAR tarballs and a set of repository tarballs
      * '''oscar-base-5.0.tar.gz''': the base OSCAR tarball stripped of almost every binary packages (rpms)
      * '''oscar-srpms-5.0.tar.gz''': the SRPMS, you only need this if you want to rebuild rpms
      * '''oscar-repo-common-rpms-5.0.tar.gz''': repository of noarch rpms used on all supported distributions
      * '''oscar-repo-DISTRO-VERSION-ARCH-5.0.tar.gz''': repository of distro and architecture specific rpms.
    * Online documentation
      Is located at: [http://svn.oscar.openclustergroup.org/wiki/oscar:5.0:install_guide]. The installation procedure of OSCAR 5 is quite different to that of previous versions. Please read the documentation!
    * OSCAR installation
      1. Download the oscar-base tarball. Unpack it in /opt. Rename the unpacked directory, if you want (e.g. /opt/oscar)
      1. In the unpacked directory execute as root the command:
         
    env OSCAR_HOME=`pwd` scripts/distro-query
             ```
             Remember the paths printed in the first two lines under "Distro repository".
          1. Copy all RPMs of the master node's distribution into the directory /tftpboot/distro/DISTRO-VERSION-ARCH or /tftpboot/rpm. Check the table at the beginning of this page for the correct DISTRO-VERSION-ARCH combination for your distribution!
          1. Download the oscar-repo-common-rpms and the oscar-repo-DISTRO-VER-ARCH tarballls suitable for the distribution(s). Unpack them in the directory /tftpboot/oscar/.
          1. In the unpacked directory (e.g. /opt/oscar) execute: 
             ```
    ./install_cluster ETH_INTERFACE
         (ETH_INTERFACE is the cluster internal interface on the head node, e.g. eth0).
    * Repositories
      Instead of copying RPMs locally to the master node you can use online repositories: [/wiki/oscar:5.0:install_guide:ch3.5_advanced_repo]
