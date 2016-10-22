---
layout: wiki
title: RepoMgmt
meta: 
permalink: "/wiki/RepoMgmt"
category: wiki
---
<!-- Name: RepoMgmt -->
<!-- Version: 2 -->
<!-- Author: efocht -->

# Managing Distribution Repositories

[Distribution repositories](/wiki/RepoPrepare/) contain the packages needed for
 * building client node images
 * resolving dependencies when installing OSCAR packages onto the master node or the client nodes

When updated packages (security or bugfixes) are made available by the distributors these can normally be installed to the master node by using commands like *up2date* or *yum update*. When the master node is configured correctly, these commands will access a remote repository with updated packages, download them into a package cache and install them onto the master node.

Mostly client OSCAR nodes are not set up for connectivity to the internet, therefore they need to be updated a different way. The OSCAR way is to update the distro repository and update the client nodes and images from it. This gives the cluster administrator the full control over which packages are updated, when and why, and avoids situations like a cluster being automatically updated over night with some untested package that breaks the installation. With a well maintained distro repository updating the master node, the client nodes or the images is very easy: use the *yume* command. Examples:

Updating the master node:

    yume update

Updating the image _oscarimage_:

    yume --installroot /var/lib/systemimager/oscarimage update

Updating the client nodes (be careful when the cluster is in production!):

    cexec yume -y update

If you want to avoid the update of certain packages, use the --exclude option should help:

    yume -y --exclude="kernel*" update

The repository maintenance consists basically of three steps:
 1. Download the updated packages to the repository.
 2. Optional: remove old packages from repository, i.e. clean it up.
 3. Regenerate the repository metadata cache. Execute the command[[BR]] 
    `yume --prepare --repo PATH_TO_REPOSITORY` [[BR]]on the master node.


The command *$OSCAR_HOME/scripts/repo-update* simplifies steps 1 and 2 of the repository maintenance. All you need is to find an URL pointing to the updated RPMs on the internet. This location must be repomd compliant, i.e. compatible with *yum* usage, because *repo-update* uses the remote metadata cache for finding the updated package versions. 

    Usage:
        repo-update [--url URL_TO_PACKAGES] [--repo LOCAL_PATH] [--prim PRIMARY.XML] \
           [--check] [--rmdup] [--verbose|-v]
    
     Download packages from an online repository to the local repository
     LOCAL_PATH or the current directory. If the repodata/primary.xml file
     from the remote repository has already been downloaded and unpacked, it
     can be passed to the program with the --prim option.
     --check only lists the files which would be downloaded but does not start
     the wget transfer.
    
     The --rmdup option leads to the removal of old versions of packages, keeping
     only the latest version. If the --url option is not specified, i.e. no downloads
     are required, the --rmdup option removes the duplicate packages (older versions)
     in the repository specified by --repo. If the --check option is specified, the
     packages which would be removed are listed.
    
     Examples:
       Check packages which would be downloaded from a FC4 updates mirror site:
    
       repo-update --url http://mirrors.dotsrc.org/fedora/updates/4/i386/ --check \
              --repo /tftpboot/distro/fedora-4-i386
    
    
       Download updates to current directory (which could be the repository) and remove
       older packages:
    
       repo-update --url http://mirrors.dotsrc.org/fedora/updates/4/i386/ --rmdup
    
    
       Remove duplicate rpms (old package versions) from the repository (usefull when
       one has copied the packages over from /var/cache/yum/*/packages/):
    
       repo-update --rmdup --repo /tftpboot/distro/fedora-4-i386

