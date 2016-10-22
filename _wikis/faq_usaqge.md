---
layout: wiki
title: faq_usaqge
meta: 
permalink: "/wiki/faq_usaqge"
category: wiki
---
<!-- Name: faq_usaqge -->
<!-- Version: 2 -->
<!-- Author: valleegr -->

[[TOC]]

[Back to the FAQ Main Page](/wiki/faq/)

# Usage

## How do I add another MPI implementation to my OSCAR cluster?

There are two aspects to adding an MPI implementation to your OSCAR cluster:

 1. Installing the MPI.  This is covered in the installation documentation for the MPI that you are installing, and is not covered here.
 1. Setting up users to use that MPI.  Once the MPI is installed, you will likely need to add a directory to the PATH (and/or LD_LIBRARY_PATH) to allow users to use it.

Note that OSCAR already ships with multiple MPI implementations; which MPI users choose to use is sometimes a highly religious issue.  As such, OSCAR provides a simple mechanism for users to choose their own MPI implementation (or use the system-provided default) known as `switcher`.  Switcher uses the environment modules software ([http://modules.sourceforge.net/](http://modules.sourceforge.net/)) to form a two-level hierarchy of persistent preferences: 
 1. the user's preferences, and 
 1. the system-provided default preferences.

If you add another MPI implementation, you want to add to OSCAR's existing mechanism for choosing which MPI to use.  First, you need to write a modulefile (see the man page `modulefile(4)` for details).  A modulefile is a trivial way to identify any environmental settings that need to be set for a user to utilize a given package, such as PATH, LD_LIBRARY_PATH, and MANPATH settings.  Here's a simple modulefile, named "foompi-1.2.3":


    #%Module -*- tcl -*-
    
    # Two internal help mechanisms
    proc ModulesHelp { } {
      puts stderr "\tSetup FooMPI in your environment."
    }
    module-whatis   "Setup FooMPI in your environment."
    
    # Don't let any other MPI module be loaded while this one is loaded
    conflict mpi
    
    # Prepend to the PATH, MANPATH, and LD_LIBRARY_PATH
    prepend-path PATH /opt/foompi-1.2.3/bin
    prepend-path LD_LIBRARY_PATH /opt/foompi-1.2.3/lib
    prepend-path MANPATH /opt/foompi-1.2.3/man

This simple modulefile performs four critical tasks:

 1. Does not let any other MPI modulefile be loaded at the same time.  This prevents user mistakes, such as accidentally specifying that they want to use two different MPI's simultaneously.
 1. Adds `/opt/foompi-1.2.3/bin` to the beginning of the current $PATH.
 1. Adds `/opt/foompi-1.2.3/lib` to the beginning of the current $LD_LIBRARY_PATH.
 1. Adds `/opt/foompi-1.2.3/man` to the beginning of the current $MANPATH.

Once you have this modulefile, you need to tell switcher about it so that it can be used by OSCAR users to select the MPI that they want to use.  Run the following command as root:

    shell# switcher mpi --add-name foompi-1.2.3 /directory/where/modulefile/exists

For example, if you created the foompi-1.2.3 file in `/home/john`, you would run:

    shell# switcher mpi --add-name foompi-1.2.3 /home/john

Switcher will copy the modulefile into its own private repository and make it available for general use.  You will need to run this command on all nodes of your OSCAR cluster to install the modulefile everywhere; the cexec command is a helpful tool here.  For example:

    # Install the modulefile on the head node
    shell# switcher mpi --add-name foompi-1.2.3 /home/john
    # Now install the modulefile on all the other nodes
    shell# cexec switcher mpi --add-name foompi-1.2.3 /home/john

You can tell if your modulefile was installed properly by running the command:

    shell$ module avail

You should see mpi/foompi-1.2.3 listed under the directory `/opt/env-switcher/share/env-switcher`.  Note that it is _not_ sufficient to simply copy your modulefile to that directory; you _must_ use the switcher command to properly register your modulefile.

Once this has been done on all nodes, users can utilize the switcher command to change their default MPI to foompi version 1.2.3 with:

    shell$ switcher mpi = foompi-1.2.3

Or the system-default MPI can be changed by root (this must be executed on all nodes, since this preference is per-node information):

    shell# switcher mpi = foompi-1.2.3 --system

The `module(1)`, `modulefile(4)`, and `switcher(1)` man pages on OSCAR clusters provide much more detail than is provided here in this FAQ entry.  Additionally, sections in the OSCAR Installation and User's Guides provide more information and common scenarios about the switcher command.

## How do I turn the headnode into an job execution node in Torque/PBS?

On the server (head node): Add the hostname of the server node to /var/spool/pbs/server_priv/nodes.

    service pbs_mom restart
    service pbs_server restart

Then verify that your server is now listed as a compute node:

    pbsnodes -a

## I got an error message while trying to compile a MPI program on the headnode using LAM/MPI's mpicc, what's the problem?

When using OSCAR 4.1 on Fedora Core 2 and 3 systems, you may see the following error messages when trying to compile MPI code using LAM/MPI's mpicc on the headnode:

    /usr/bin/ld: cannot find -laio
    collect2: ld returned 1 exit status
    mpicc: No such file or directory

This can be solved by installing the libaio-devel RPM on the headnode which should be in the /tftpboot/rpm directory. The compute nodes should have the RPM installed already. 

## How do i add a user to the cluster?

All the following commands should be executed with root privileges.
  * Make sure both the OPIUM and the sync_files OSCAR packages are installed.
  * Add the user on the headnode executing _adduser_.
  * Make sure the sync_files configuration files enables the synchronization of the following files:

    syncfile /etc/passwd
    syncfile /etc/group
    syncfile /etc/shadow
    syncfile /etc/gshadow
  * Synchronize the compute nodes with sync_file: _/opt/syn_files/bin/sync_files_.
  * For access to the compute nodes without password, the new user should synchronize his ssh_keys executing _ssh-oscar_.