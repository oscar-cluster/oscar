---
layout: wiki
title: AdminGuide/Commands
meta: 
permalink: "wiki/AdminGuide/Commands"
category: wiki
folder: wiki
---
<!-- Name: AdminGuide/Commands -->
<!-- Version: 4 -->
<!-- Author: valleegr -->
[Documentations](../Document) > [User Documentations](../Support) > [Administration Guide](../AdminGuideDoc)

## Chapter 3: OSCAR Management Commands

### 3.1 Overview

This section covers OSCAR management using a command line, where functionality does not exist within the GUI.
Most of the commands are either mksi* or si_* (i.e., SIS commands).

Topics covered include:
 * Deleting an image (mksiimage)

Note that since most of the commands are SIS commands. It means that these commands do not update the OSCAR database (ODA) and therefore may result in a de-synchronization of the SIS database, the actual file system and the OSCAR database.

### 3.2 Deleting node images

It is sometimes useful to be able to delete one or more of the node images which OSCAR uses to provision the client nodes or to change which image is sent to a node when it joins the cluster.

To delete an OSCAR image, you need to first unassign the image from the client(s) which are currently using that image and then run the command _mksiimage_.

There is currently no way to change which image is assigned to a node from within the OSCAR GUI, so first you will need to delete the client node(s) if you wish to change which image is used on a particular node.  It is not necessary if the image simply changes, this procedure is only necessary to completely change a node to use a different image entirely.  To do so, invoke the OSCAR Wizard and select "Delete OSCAR Clients...".

_mksiimage_ is a command from SystemInstaller which is used to manage SIS images on the headnode (image server).

Assuming the name of your image is _oscarimage_, here are the steps you need to do to fully delete an OSCAR image.

First delete the client(s) associated with the image, then execute:

    # mksiimage --delete --name oscarimage

If this command does not work for some reason, you can also use the command _si_rmimage_ to delete the image, just pass it the name of the image as argument.

_si_rmimage_ is a command from SystemImager, the system OSCAR uses to deploy images to the compute nodes.  SystemImager images are typically stored in _/var/lib/systemimager/images_.

*Note:* If you want to use the _si_rmimage_ command, execute the following commands to delete all data:

    # si_rmimage oscarimage -force

### 3.3 Managing Distribution Repositories

Distribution repositories contain the packages needed for
 * building client node images
 * resolving dependencies when installing OSCAR packages onto the master node or the client nodes 

First of all, it is still possible to apply updates using the standard package management systems (_yum_, _aptitude_ and so on). For instance, when updated packages (security or bugfixes) are made available by the distributors, these can normally be installed to the master node by using commands like _up2date_ or _yum update_. When the master node is configured correctly, these commands will access a remote repository with updated packages, download them into a package cache and install them onto the master node.

Mostly client OSCAR nodes are not set up for connectivity to the internet, therefore they need to be updated a different way. The OSCAR way is to update the distribution repository and update the client nodes and images from it. This gives the cluster administrator the full control over which packages are updated, when and why, and avoids situations like a cluster being automatically updated over night with some untested package that breaks the installation. With a well maintained distribution repository updating the master node, the client nodes or the images is very easy: use the _yume_ command.
We do not currently provide any tool to ease the update of the distribution repository, system administrators have to perform this task manually.

### 3.4 Examples

The following paragraphs give examples of system administration on a RPM based system.

#### Example: Updating the master node
 
    yume update
     ```
    
    === Example: Updating the image oscarimage ===
     ```
    yume --installroot /var/lib/systemimager/images/oscarimage update <file>
     ```
    
     '''If you updated the image kernel, you need to regenerate the ramdisk files for that kernel'''
    
       * Just edit the systemconfig.conf file to point to the new kernel, located on the head node in: `/var/lib/systemimager/images/oscarimage/etc/systemconfig/` (if you didn't use the default name for your client image ("oscarimage"), edit the path appropriately)
       ```
    >> nano /var/lib/systemimager/images/oscarimage/etc/systemconfig/systemconfig.conf
   
   * confirm that the following option is setup on the above systemconfig.conf file:
   
    >> CONFIGRD = YES
       ```
    
    
       * Done! Now any newly created client that uses this image will boot by default into the new kernel
    
    === Example: Updating the client nodes (be careful when the cluster is in production!) ===
     ```
    cexec yume -y update
     ```
    
     If you want to avoid the update of certain packages, use the --exclude option should help:
     ```
    yume -y --exclude="kernel*" update
     ```
    
    === Example: repository maintenance ===
    
    The repository maintenance consists basically of three steps:
      1. Download the updated packages to the repository.
      1. Optional: remove old packages from repository, i.e. clean it up.
      1. Regenerate the repository metadata cache. Execute the command `yume --prepare --repo PATH_TO_REPOSITORY` on the master node. 
    
    The command `$OSCAR_HOME/scripts/repo-update` simplifies steps 1 and 2 of the repository maintenance. All you need is to find an URL pointing to the updated RPMs on the internet. This location must be repomd compliant, i.e. compatible with yum usage, because repo-update uses the remote metadata cache for finding the updated package versions.
    
    ```
    Usage:
        repo-update [--url URL_TO_PACKAGES] [--repo LOCAL_PATH] [--prim PRIMARY.XML] \
        [--check] [--rmdup] [--verbose|-v]

Download packages from an on-line repository to the local repository LOCAL_PATH or the current directory. If the `repodata/primary.xml` file from the remote repository has already been downloaded and unpacked, it can be passed to the program with the _--prim_ option. _--check_ only lists the files which would be downloaded but does not start the wget transfer.

The _--rmdup_ option leads to the removal of old versions of packages, keeping only the latest version. If the --url option is not specified, i.e. no downloads are required, the --rmdup option removes the duplicate packages (older versions) in the repository specified by --repo. If the --check option is specified, the packages which would be removed are listed.

#### Example: Repository update

Check packages which would be downloaded from a FC4 updates mirror site::
 ```
repo-update --url http://mirrors.dotsrc.org/fedora/updates/4/i386/ --check \
  --repo /tftpboot/distro/fedora-4-i386
 ```

Download updates to current directory (which could be the repository) and remove older packages::
 ```
repo-update --url http://mirrors.dotsrc.org/fedora/updates/4/i386/ --rmdup
 ```

 Remove duplicate rpms (old package versions) from the repository (usefull when one has copied the packages over from _/var/cache/yum/*/packages/_)::
 ```
repo-update --rmdup --repo /tftpboot/distro/fedora-4-i386
 ```

   Once your repository is fully updated, before you really update(yume update) your cluster with the new repository, you may need to update the repository metadata too by the following command:
   ```
yume --prepare --repo /tftpboot/distro/fedora-4-i386
   ```

