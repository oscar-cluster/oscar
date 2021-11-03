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
    
### OSCAR_unstable Quick Start Guide for CentOS-7, AlmaLinux-8, openSUSE-15.3

1. Notes:
    * CentOS-6 is not supported anymore due to EOL of product. Though, packages are still availlable in case they are still needed. Installation process is similar to CentOS-7 except that you need to use CentOS vault repositories:
    `curl https://www.getpagespeed.com/files/centos6-eol.repo --output /etc/yum.repos.d/CentOS-Base.repo`
    `yum -y install epel-release-6-8.noarch`
    `curl https://www.getpagespeed.com/files/centos6-epel-eol.repo --output /etc/yum.repos.d/epel.repo`
    * This Guide can also be used for a RHEL 7 or 8 install, but it is not tested.
    * OpenSUSE-15 is newly supported and still incomplete.
1. Install AlmaLinux-8.x or CentOS-7.x or openSUSE-15.3 or Debian-10 or Debian-11 (or their Ubuntu equivalent) base server (+ X11 if you are working localy)
1. Setup hostname, and network.
1. Configure and enable the required repositories:
    * CentOS-7:
       - `yum -y install http://fr2.rpmfind.net/linux/epel/7/x86_64/e/epel-release-7-5.noarch.rpm`
       - `yum -y install http://svn.oscar.openclustergroup.org/repos/unstable/rhel-7-x86_64/oscar-release-6.1.3-0.20210426.el8.noarch.rpm`
    * AlmaLinux-8:
       - `dnf -y install dnf-plugins-core`
       - `dnf config-manager --set-enabled PowerTools`
       - `dnf -y install epel-release`
       - `dnf -y install http://svn.oscar.openclustergroup.org/repos/unstable/rhel-7-x86_64/oscar-release-6.1.3-0.20210426.el8.noarch.rpm`
    * openSUSE-15.3:
       - `zypper install http://www.usablesecurity.net/OSCAR/repos/unstable/suse-15-x86_64/oscar-release-6.1.3-0.20210402.noarch.rpm`
    * Debian-10:
       - cat >> /etc/apt/sources.list.d/oscar.list <<EOF
deb [trusted=yes] http://www.usablesecurity.net/OSCAR/repos/unstable/debian-10-x86_64 dists/buster/binary-amd64/
EOF
    * Debian-11:
       - cat >> /etc/apt/sources.list.d/oscar.list <<EOF
deb [trusted=yes] http://www.usablesecurity.net/OSCAR/repos/unstable/debian-11-x86_64 dists/bullseye/binary-amd64/
EOF

1. make sure that your mta (mail transfert agent) is postfix if you want mtaconfig to  be of any use.
   if postfix is not your default mta, then do a:

    * AlmaLinux-8:
       - `dnf -y install postfix; yum remove sendmail exim`
    * CentOS-7:
       - `yum -y install postfix; yum remove sendmail exim`
    * OpenSUSE-15:
       - `zypper --non-interactive install --no-recommends --download-in-advance postfix; zypper --non-interactive remove sendmail exim`
    * Debian-10, Debian-11:
       - apt-get install postfix
1. Update SELinux config (/etc/selinux/config)

    SELINUX=disabled
1. disable ipv6 in /etc/sysctl.conf (and reboot)

    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
1. Install main oscar package:
    * AlmaLinux-8:
       - `dnf -y install oscar`
    * CentOS-7:
       - `yum -y install oscar`
    * OpenSUSE-15:
       - `zypper --non-interactive install --no-recommends --download-in-advance -f oscar`

1. check /etc/oscar/oscar.conf
1. check /etc/oscar/supported_distros.txt
1. Configure oscar for your distro:

    **CentOS-7:**
    `oscar-config --setup-distro centos-7-x86_64`

    **RHEL-7:**
    `oscar-config --setup-distro rhel-7-x86_64`
    
    **AlmaLinux-8:**
    `oscar-config --setup-distro almalinux-8-x86_64`
    
    **RHEL-8:**
    `oscar-config --setup-distro rhel-8-x86_64`
    
    **OpenSUSE-15:**
    `oscar-config --setup-distro opensuse-15-x86_64`
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
