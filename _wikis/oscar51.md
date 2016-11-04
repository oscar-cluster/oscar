---
layout: wiki
title: oscar51
meta: 
permalink: "wiki/oscar51"
category: wiki
---
<!-- Name: oscar51 -->
<!-- Version: 2 -->
<!-- Author: dikim -->

** Release features
  * [Supported distributions](DistroSupport)[[BR]]
    Many of these distros are new for OSCAR, which shows that the infrastructure is now quite flexible. And the PS3 support is something quite unique, a big thanks to DongInn and Bernard for it!
  * OSCAR database (ODA):
    * Postgresql support
    * Code janitoring
  * New OSCAR Package format, using native distribution package formats
  * Ready to use the on-line repository

 * Quick install guide
   1. download the repo tarballs you are interested in. The tarballs are available 
      [http://svn.oscar.openclustergroup.org/php/download.php?d_name=beta here] [[BR]]
      For example:

    oscar-repo-common-rpms-5.1b1.tar.gz
    oscar-repo-rhel-5-x86_64-5.1b1.tar.gz
   1. unpack the tarballs:

    mkdir -p /tftpboot/oscar
    tar xzfC oscar-repo-common-rpms-*.tar.gz /tftpboot/oscar/
    tar xzfC oscar-repo-rhel-5-x86_64-*.tar.gz /tftpboot/oscar/
   1. install yume (supposing yum is already there):
``` 
yum install createrepo /tftpboot/oscar/common-rpms/yume*.rpm 
```
      Note: since yum is not available on RHEL4, you have to do this:

    cd /tftpboot/oscar/rhel-4-i386
    rpm -ivh yum-oscar-2.4.3-1.noarch.rpm python-elementtree-1.2.6-6.1ef.i686.rpm \
    python-urlgrabber-2.9.8-2ef.noarch.rpm ../common-rpms/yume-2.7-2.noarch.rpm \
    ../common-rpms/createrepo-0.4.3-5.1e.noarch.rpm
   1. set up the distro repository in /tftpboot/distro/... Look at [this](InstallGuidePreparing#DistributionRepositories) for instructions.
   1. install oscar-base rpm

    yume --repo /tftpboot/oscar/common-rpms install oscar-base
   1. start installation, for example:

    cd /opt/oscar
    env OSCAR_VERBOSE=3 ./install_cluster ETH_INTERFACE 
     (ETH_INTERFACE is the cluster internal interface on the head node, e.g. eth0).

    * Repositories
      Instead of copying distro RPMs locally to the master node you can use online repositories: [oscar:5.1:install_guide:ch3.5_advanced_repo]
