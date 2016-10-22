---
layout: wiki
title: quick_start_guide_for_rhel
meta: 
permalink: "/wiki/quick_start_guide_for_rhel"
category: wiki
---
<!-- Name: quick_start_guide_for_rhel -->
<!-- Version: 15 -->
<!-- Author: olahaye74 -->

## OSCAR_unstable Quick Start Guide for CentOS/RHEL version 6.x and 7.x (quite similar for other distros)

1. Install CentOS-6.x or CentOS-7.x base server (+ X11 if you are working localy)
2. Setup hostname, and network.
3. make sure that your mta (mail transfert agent) is postfix if you want mtaconfig to  be of any use.[[BR]]
   if postfix is not you default mta, then do a:

    yum -y install postfix; yum remove sendmail exim
4. Install the required repositories:

    # CentOS-6:
    yum -y install http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
    yum -y install http://svn.oscar.openclustergroup.org/repos/unstable/rhel-6-x86_64/oscar-release-6.1.2r11033-1.el6.noarch.rpm
    
    # CentOS-7:
    yum -y install http://fr2.rpmfind.net/linux/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
    yum -y install http://svn.oscar.openclustergroup.org/repos/unstable/rhel-7-x86_64/oscar-release-6.1.2r11033-1.el7.noarch.rpm
5. Update SELinux config (/etc/selinux/config)

    SELINUX=disabled
6. disable ipv6 in /etc/sysctl.conf (and reboot)[[BR]]

    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
7. Install main oscar package:

    yum install oscar
8. check /etc/oscar/oscar.conf
9. check /etc/oscar/supported_distros.txt
10. Configure oscar for your distro:

    # CentOS-6:
    oscar-config --setup-distro centos-6-x86_64
    
    # CentOS-7:
    oscar-config --setup-distro centos-7-x86_64
11. Bootstrapp oscar (install packages needed for your distro and do some basic configuration)

    oscar-config --bootstrap
12. Start the OSCAR installer wizard;

    oscar_wizard -d install
13. Wizard STEP1: Select experimental, then select: (*bold* means mandatory)
* *apitest*
* *base*
* blcr
* *c3*
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
* *oda*
* openmpi
* opium
* pvm
* *sc3*
* seliun
* *sis*
* *switcher*
* *sync-files*
* torque
* *yume*
15. Wizard STEP2: Configure selected oscar packages
16. Wizard STEP3: Install Oscar server packages
- Fix TFTP_DIR in /etc/systemimager/systemimager.conf
- Fix server_args in /etc/xinetd.d/tftp (tftpboot dir)
- restart si_netbootmond

    service systemimager-server-netbootmond restart
17. Wizard STEP4: Build Client image
18. Wizard STEP5: Define oscar clients
19. Wizard STEP6: Setup Networking
20. - Assign macs to nodes (if used start collecting MACS, then stop it before going further)
21. - Enable Install mode
22. - Configure DHCP server
23. - Setup Network Boot
24. edit /etc/dhcp/dhcpd.conf
- correct the gateway (option routers), then restart dhcpd (BUG)
- optionally add dns infos (those entries are ommited if you're using non routable IPs)

      option domain-name "domain.company.com";
      option domain-name-servers #.#.#.#, #.#.#.#;
25. Add postinstall scripts to configure bootloader and network (feature broken in system-configurator).

    cd /var/lib/systemimager/scripts/post-install/
    sudo wget http://svn.oscar.openclustergroup.org/pkgs/downloads/sis_postinstall/13all.keyboard_fr    # (Optional: will set node console keyboard to fr_FR)
    sudo wget http://svn.oscar.openclustergroup.org/pkgs/downloads/sis_postinstall/15all.grub_install   # For grub based distros (centos-6, ...)
    sudo wget http://svn.oscar.openclustergroup.org/pkgs/downloads/sis_postinstall/14all.grub2_install  # For grub-2 based distros (centos-7, ...)
    sudo wget http://svn.oscar.openclustergroup.org/pkgs/downloads/sis_postinstall/16all.network_config # Edit this to update DNS config
25. Monitor cluster deployment
26. PXE boot all nodes
27. Fix BUGS:
   - FIXED: ~~re-enable nodes (remove dead keywork) in /etc/c3.conf (do not touch the "dead remove_for...." line)~~
   - FIXED: ~~BUG: enable and start munge and gmond on nodes (should be started in step 7, but step7 fails if they don't start)~~
28. Wizard STEP7: Complete cluster setup
   - FIXED: ~~BUG: enable and start munge and gmond on nodes~~
   - FIXED: ~~BUG: enable gmetad (and optionaly gmond if head runs jobs) on the headnode.~~
29. Wizard STEP8: Test cluster setup


## OSCAR_unstable Quick Remove script for CentOS/RHEL/Fedora

This script is useful to restart from scratch an OSCAR Install. It's not perfect. All files modified (with a .oscarback backup) are not restored for instance.


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