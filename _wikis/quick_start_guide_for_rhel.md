---
layout: wiki
title: quick_start_guide_for_rhel
meta: 
permalink: "wiki/quick_start_guide_for_rhel"
category: wiki
---
<!-- Name: quick_start_guide_for_rhel -->
<!-- Version: 15 -->
<!-- Author: olahaye74 -->
[Documentations](Document) > [User Documentations](Support) 
    
### OSCAR_unstable Quick Start Guide for CentOS/RHEL version 6.x and 7.x (quite similar for other distros)

1. Install CentOS-6.x or CentOS-7.x base server (+ X11 if you are working localy)
1. Setup hostname, and network.
1. make sure that your mta (mail transfert agent) is postfix if you want mtaconfig to  be of any use.
   if postfix is not your default mta, then do a:

    `yum -y install postfix; yum remove sendmail exim`
1. Install the required repositories:
    * CentOS-6:
       - `yum -y install http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm`
       - `yum -y install http://svn.oscar.openclustergroup.org/repos/unstable/rhel-6-x86_64/oscar-release-6.1.3-0.20180524.el6.noarch.rpm`
    * CentOS-7:
       - `yum -y install http://fr2.rpmfind.net/linux/epel/7/x86_64/e/epel-release-7-5.noarch.rpm`
       - `yum -y install http://svn.oscar.openclustergroup.org/repos/unstable/rhel-7-x86_64/oscar-release-6.1.3-0.20180524.el7.noarch.rpm`
1. Update SELinux config (/etc/selinux/config)

    SELINUX=disabled
1. disable ipv6 in /etc/sysctl.conf (and reboot)

    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
1. Install main oscar package:
    `yum install oscar`
1. check /etc/oscar/oscar.conf
1. check /etc/oscar/supported_distros.txt
1. Configure oscar for your distro:

    **CentOS-6:**
    `oscar-config --setup-distro centos-6-x86_64`
    
    **CentOS-7:**
    `oscar-config --setup-distro centos-7-x86_64`
1. Bootstrapp oscar (install packages needed for your distro and do some basic configuration)

    `oscar-config --bootstrap`
1. Start the OSCAR installer wizard;

    `oscar_wizard -d install`
1. Wizard STEP1: Select experimental, then select: (**bold** means mandatory)
* **apitest**
* **base**
* blcr
* **c3**
* disable-services
* ganglia
* jobmonarch
* maui
* mtaconfig
* munge
* naemon
* netbootmgr
* nfs
* ntpconfig
* **oda**
* openmpi
* opium
* pvm
* **sc3**
* seliun
* **sis**
* **switcher**
* **sync-files**
* torque
* **yume**
1. Wizard STEP2: Configure selected oscar packages
1. Wizard STEP3: Install Oscar server packages
    - Fix TFTP_DIR in /etc/systemimager/systemimager.conf
    - Fix server_args in /etc/xinetd.d/tftp (tftpboot dir)
    - restart si_netbootmond
    - service systemimager-server-netbootmond restart
1. Wizard STEP4: Build Client image
1. Wizard STEP5: Define oscar clients
1. Wizard STEP6: Setup Networking
   - Assign macs to nodes (if used start collecting MACS, then stop it before going further)
   - Enable Install mode
   - Configure DHCP server
   - Setup Network Boot
1. edit /etc/dhcp/dhcpd.conf
   - correct the gateway (option routers), then restart dhcpd (BUG)
   - optionally add dns infos (those entries are ommited if you're using non routable IPs)
      _option domain-name "domain.company.com";_
      _option domain-name-servers #.#.#.#, #.#.#.#;_
1. Add postinstall scripts to configure bootloader and network (feature broken in system-configurator).

    _cd /var/lib/systemimager/scripts/post-install/   
    sudo wget http://svn.oscar.openclustergroup.org/pkgs/downloads/sis_postinstall/13all.keyboard_fr    # (Optional: will set node console keyboard to fr_FR)  
    sudo wget http://svn.oscar.openclustergroup.org/pkgs/downloads/sis_postinstall/16all.network_config # Edit this to update DNS config_
1. Monitor cluster deployment
1. PXE boot all nodes
1. Wizard STEP7: Complete cluster setup
1. Wizard STEP8: Test cluster setup


### OSCAR_unstable Quick Remove script for CentOS/RHEL/Fedora
 
This script is useful to restart from scratch an OSCAR Install. It's not perfect. All files modified (with a .oscarback backup) are not restored for instance.


``` bash
#!/bin/bash
sudo oscar-config -t
sudo yum -y remove oscar drmaa-python ganglia* jobmonarch* "ganglia*" \ 
                   "jobmonarch*" "*torque*" "*openmpi*" "*systemimager*" \ 
                   netbootmgr opkgc perl-Qt atftp-server dhcp \
                   modules-default-manpath-oscar modules-oscar perl-OSCAR \
                   "naemon*" "nagios*" nrpe "postgresql" "rrdtool*" "httpd*" \
                   "slurm*" oscar-installer openmpi-switcher-modulefile
sudo rm -rf /etc/oscar \
            /etc/ganglia \
            /etc/naemon \
            /etc/systemimager \
            /etc/systeminstaller \
            /var/log/oscar \
            /var/lib/oscar \
            /var/lib/oscar-packager
```
