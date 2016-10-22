---
layout: wiki
title: TipWindowsAndLinux
meta: 
permalink: "/wiki/TipWindowsAndLinux"
category: wiki
---
<!-- Name: TipWindowsAndLinux -->
<!-- Version: 1 -->
<!-- Author: jparpail -->

# How to install a cluster with windows and linux using OSCAR

I'm doing my final project for my degree in computer science in Girona, Spain. To do the project I need a linux cluster to run parallel radiosity algorithms. 

Searching computers for the project, We have found 4 hp proliant dl145 that are running Windows on another department. We talked with the admin of the computers and he gave us the permission for using the computers.

In this document I will explain how I have configured the cluster. It's a specific configuration, that can be useful for a lot of people and a way to know a little bit more about OSCAR possibilities.

The beginning... I have the machines with windows installed on "hda" drive . The master node have two ethernet links, eth0 to the internet and eth1 to the cluster. All nodes have one ethernet link using  eth1 for the cluster.

To install OSCAR I have added one more hard disk to all the machines (hdc).

After that, I have configured all nodes to boot first from eth1 at startup.

Once I have all the hardware configured, I start installing the operating system on the headnode. For this purpose I use Suse, because it's the distribution I have used to do all the previous tests, but it's not an important decision really.

Now I download and uncompress all the OSCAR stuff. I'm not talking about how to install OSCAR on this document, because there are some nice manuals out there in the wiki :).

The first thing I have to do in OSCAR is edit the /opt/oscar/oscarsamples/ide.disk file and replace  ext3 file system with reiserfs  and replace all the hda acurrencies by hdc, because I have installed the new hard drives on the second IDE channel as master.

After this modification I have proceed with the OSCAR installation itself. After building the Image for the cluster I have edit the file `/var/lib/systemimager/images/oscarimage/etc/systemimager/autoinstallscript.conf` . In this file I have added the hda drive. Systemimager will use the first drive that it found by default, so I have to specify that I will use `hdc` for linux instead the first drive.

Now I run the command 

    $ si_mkautoinstallscript --image oscarimage --force -ip-assignment static -post-install reboot 

to rebuild the file  `/var/lib/systemimager/scripts/oscarimage.master` including `hda`.

Once the file is updated with the last command I will edit  the file again. The first thing I need to delete is the information about hda that have been modified. I need to erase all the commands referred to hda. After that, I need to modify the configuration about which ethernet card will be configured, by default is eth0, but the cluster running windows is configured with the link in eth1, no problem: I have to go to the `[Interface0]` section and  put `DEVICE=eth1`.

If everything goes fine, the machines will install OSCAR without deleting or modifying the windows partition.

After these steps, we have to solve the boot process of the nodes. To do this I will load the kernel on the nodes via network using PXE.

I assume all the computers have the same hardware, so I will use the headnode's kernel on the other nodes as well. I copy the kernel to `/tftpboot/` directory. Keep in mind that  in the nodes, the root ( / ) is on `/dev/hdc6`. That's the reason why I need to do a new initrd file. 

*WARNING*: After doing this, make a backup of /boot/initrd file, otherwise, it will be overwritten.


    $ mkinitrd -d /dev/hdc6

After that, copy the new initrd file to `/tftpboot` and restore the actual initrd file on the machine.

I need to edit the file `/tftpboot/localboot` in order to specify where a node boots from. The file may result as follow:

    DEFAULT boot
    LABEL boot
    KERNEL vmlinuz-2.6.13-15-default
    APPEND initrd=initrd-2.6.13-15-default 
    DISPLAY message.txt
    PROMPT 1
    TIMEOUT 50

With that, the machine will boot from the initrd and loads the kernel located at `/tftpboot/`

Once the file localboot is modified, I need to run the command:   `cp /tftpboot/localboot /etc/systemimager/pxelinux.cfg/syslinux.cfg.localboot` to be sure that the same file is on that two locations.

I have used a SMP computers and the kernel uses a few modules that are needed by  the nodes as well. For that reason, I have copied the contents of the /lib directory of the headnode to the nodes.

    $ cp -a /lib /var/lib/systemimager/images/oscarimage/

After these changes, I finish the steps of the OSCAR installation and all it's done.

And  that's all I need to do in order to have the cluster up and running under linux without deleting the windows partition.

In case the headnode are powered off or running windows, the nodes will boot windows. As soon as the headnode is running linux, the nodes will found a PXE server and will boot linux.

If you're running linux and want to go to windows you can run:

    $ cexec shutdown -r now
    $ shutdown -r now

I need to find a way to  change from windows to linux (actually I reboot manually or via VNC all the nodes). Because I  haven't found a way to reboot all the windows computers manually.

Finally I would like to thanks Sergi Diaz for helping me with the translation.

If you have any questions feel free to mail me at paladi[at]gmail.com

Adrià Forés Herranz