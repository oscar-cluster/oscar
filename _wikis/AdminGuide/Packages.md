---
layout: wiki
title: AdminGuide/Packages
meta: 
permalink: "wiki/AdminGuide/Packages"
category: wiki
---
<!-- Name: AdminGuide/Packages -->
<!-- Version: 15 -->
<!-- Author: dikim -->

[[TOC]]

[back to Table of Contents](../AdminGuideDoc)

# 4 Package Notes

== 4.1 Torque Resource Manager == #Torque

License: OpenPBS (Portable Batch System) v2.3 Software License

### 4.1.1 Overview

The Torque resource manager consists of three major components:

 * The Torque server. 
   * This runs on the OSCAR head node.
   * It controls the submission and running of jobs.
   * It also tracks the current state of cluster resources.
 * A "mom" daemon on each cluster node.
   * responsible for actually starting and stopping jobs on the client nodes.

Torque also has a first-in-first-out scheduler which it can use, but by default OSCAR uses the Maui Scheduler as it is more flexible and powerful.  The two programs are quite tightly integrated, but there is some overlap in functionality due to the fact that they were designed originally as separate utilities.

From the point of view of the user, most interaction takes place with the Torque resource manager, as that is the entry point for job script submission.  

### 4.1.2 Commands

All Torque commands can be found under `/opt/pbs/bin` on the OSCAR head node, but are included in the path in a standard OSCAR installation. There are man pages available for these commands, but here are the most popular with some basic options:

 * `qsub`: submits job to Torque
 * `qdel`: deletes Torque job
 * `qstat [-n]`: displays current job status and node associations
 * `pbsnodes [-a]`: displays node status
 * `pbsdsh`: distributed process launcher
 * `xpbs`: X-windows Torque client.   Simplifies both user and administrative tasks.

### 4.1.3 Submitting a Job

The qsub command is not necessarily intuitive. Here are some handy tips to know:

 * Be sure to read the qsub man page.
 * qsub only accepts a script filename for a target.
 * The target script cannot take any command line arguments.
 * For parallel jobs, the target script is only launched on ONE node. Therefore the script is responsible for launching all processes in the parallel job.
 * One method of launching processes is to use the pbsdsh command within the script used as qsub’s target. pbsdsh will launch its target on all allocated processors and nodes (specified as arguments to qsub). Other methods of parallel launch exist, such as mpirun, included with each of the MPI packages.

Here is a sample qsub command line:

    $ qsub -N my_jobname -e my_stderr.txt -o my_stdout.txt -q workq -l \
      nodes=X:ppn=Y:all,walltime=1:00:00 script.sh

Here is the contents of the *script.sh* file:

    #!/bin/sh
    echo Launchnode is ‘hostname‘
    pbsdsh /path/to/my_executable
    # All done

Alternatively, you can specify most of the qsub parameters in script.sh itself, and the qsub command would become:

    $ qsub -l nodes=X:ppn=Y:all,walltime=1:00:00 script.sh

Here is the contents of the script.sh file:

    #!/bin/sh
    #PBS -N my_jobname
    #PBS -o my_stdout.txt
    #PBS -e my_stderr.txt
    #PBS -q workq
    echo Launchnode is ‘hostname‘
    pbsdsh /path/to/my_executable
    # All done

Notes about the above examples:
 * "all" is an optional specification of a node attribute, or "resource".
 * "workq" is a default queue name that is used in OSCAR clusters.
 * 1:00:00 is in HH:MM:SS format (although leading zeros are optional).

### 4.1.4 Torque LAM/MPI Sample Script


    #!/bin/sh
    #PBS -N  C10-0.0
    #Add other PBS options here.
    #redirect error msg to err_pbs.txt
    #PBS -e /home/oscartest/lamtest/err_pbs.txt
    #redirect pbs output msgs to err_pbs.txt
    #PBS -o /home/oscartest/lamtest/out_pbs.txt
    #PBS -q workq
           
    lamboot -v $PBS_NODEFILE
    cd /home/oscartest/lamtest
    DATE=\`date +%c\`
    echo Job C10-0.0 started at $DATE
    mpirun -np 16 ./eqn10p.x
    lamhalt -v $PBS_NODEFILE
    DATE=\`date +%c\`
    echo Job finished at $DATE
    echo
           
    #Comments only after execution section
    #to run this job alone type in directory
    #/home/oscartest/lamtest:
    #qsub -l nodes=8:ppn=2 ./qscript.sh

This script uses LAM-MPI to execute the program `/home/oscartest/lamtest/eqn10p.x` on the nodes provided by Torque.   After running lamboot on the nodes provided, the script moves to the target directory and runs eqn10p.x using mpirun with 16 processes.  Then the script cleans up after itself by running lamhalt.  The 16 processes are started regardless of how many nodes Torque assigns.

### 4.1.5 Sample Script for MPICH


    #!/bin/sh
    #PBS -N  MPICH_Test
    # Add other PBS options here.
    #redirect error msg to err_pbs.txt 
    #PBS -e /home/oscartest/mpich/err_pbs.txt
    #redirect pbs output msgs to err_pbs.txt
    #PBS -o /home/oscartest/mpich/out_pbs.txt
    #PBS -q workq
        
    cd /home/oscartest/mpich
    DATE=\`date +%c\`
    echo Job MPICH_Test started at $DATE
    time mpirun -np 16 -machinefile $PBS_NODEFILE ./ring
    DATE=\`date +%c\`
    echo Job finished at $DATE
      
    #Comments only after execution section
    #to run this job alone type in directory
    #/home/oscartest/mpich/
    #qsub -l nodes=8:ppn=2 ./qscript.sh
  
This script uses MPICH to execute the program `/home/oscartest/mpich/ring` on the nodes provided by Torque.   The script moves to the target directory and runs the program ring using mpirun with 16 processes using the file $PBS_NODEFILE as the machinefile as the node list.  Initialization and clean-up steps are not necessary when using MPICH.  As with LAM the 16 processes are started regardless of how many nodes Torque assigns.

### 4.1.6 Environment Variables

There are a number of predefined environment variables which the Torque resource manager makes available to scripts run through it.  These can be useful for debugging Torque setup files as well as data organization.

The following environment variables relate to the submission machine: 
| *Option* | *Description* |
| PBS_O_HOST	| The host machine on which the qsub command was run. |
| PBS_O_LOGNAME	| The login name on the machine on which the qsub was run. |
| PBS_O_HOME	| The home directory from which the qsub was run. |
| PBS_O_WORKDIR	| The working directory from which the qsub was run. |

The following variables relate to the environment where the job is executing: 
| *Option* | *Description* |
| PBS_ENVIRONMENT	| This is set to PBS_BATCH for batch jobs and to PBS_INTERACTIVE for interactive jobs. |
| PBS_O_QUEUE	| The original queue to which the job was submitted. |
| PBS_JOBID	| The identifier that PBS assigns to the job. |
| PBS_JOBNAME	| The name of the job. |
| PBS_NODEFILE	| The file containing the list of nodes assigned to a parallel job. |

### 4.1.7 Additional Resources

More information about using and configuring Torque is available on the Cluster Resources website at [http://www.clusterresources.comdoku.php?id=torque:torque_wiki]

== 4.2 MAUI Scheduler == #Maui

Official website: http://www.clusterresources.com/pages/products/maui-cluster-scheduler.php

License: [MAUI License](Maui_license)

### 4.2.1 Overview

The Maui scheduler takes care of scheduling jobs on the cluster based on a series of sophisticated algorithms which take into account current system resources, cluster usage rates, past user activity, and many other factors.  These algorithms are very flexible and are configurable by the cluster administrator.  

### 4.2.2 Maui Commands

There are several commands available to the Maui Scheduler which can aid in the debugging of problems with Torque or Maui configurations.  These commands are located in `/opt/maui/bin` and generally need to be run with root permissions.  Refer to maui documentation for further detail about these commands.

 * diagnose: displays information about nodes, jobs and other resources
 * checkjob: displays less verbose information about particular jobs
 * showstats: shows usage stats for scheduled jobs

### 4.2.3 Additional Resources

Additional documentation and resources for Maui are available on the project's website: [http://www.clusterresources.com/pages/resources/documentation.php]

== 4.3 C3 == #C3

Official website: http://www.csm.ornl.gov/torc/c3/

License:
 Permission to use, copy, modify, and distribute this software and
 its documentation for any purpose and without fee is hereby granted
 provided that the above copyright notice appear in all copies and
 that both the copyright notice and this permission notice appear in
 supporting documentation.

### 4.3.1 Overview

The Cluster Command Control (C3) tools are a suite of cluster tools developed at Oak Ridge National Laboratory that are useful for both administration and application support. The suite includes tools for cluster-wide command execution, file distribution and gathering, process termination, remote shutdown and restart, and system image updates.

A short description of each tool follows:
 * cexec: general utility that enables the execution of any standard command on all cluster nodes
 * cget: retrieves files or directories from all cluster nodes
 * ckill: terminates a user specified process on all cluster nodes
 * cpush: distribute files or directories to all cluster nodes
 * cpushimage: update the system image on all cluster nodes using an image captured by the SystemImager tool
 * crm: remove files or directories from all cluster nodes
 * cshutdown: shutdown or restart all cluster nodes
 * cnum: returns a node range number based on node name
 * cname: returns node names based on node ranges
 * clist: returns all clusters and their type in a configuration file

The default method of execution for the tools is to run the command on all cluster nodes concurrently. However, a serial version of cexec is also provided that may be useful for deterministic execution and debugging. Invoke the serial version of cexec by typing cexecs instead of cexec. For more information on how to use each tool, see the man page for the specific tool.

### 4.3.2 File Format

Specific instances of C3 commands identify their compute nodes with the help of _cluster configuration files_: files that name a set of accessible clusters and describe the set of machines in each accessible cluster. _/etc/c3.conf_, the default cluster configuration file, should consist of a list of _cluster descriptor blocks_: syntactic objects that name and describe a single cluster that is accessible to that system’s users. The following is an example of a default configuration file that contains exactly one cluster descriptor block: a block that describes a cluster of 64 nodes:

    cluster cartman {
      cartman-head:node0 #head node
      node[1-64] #compute nodes
    }

The cluster tag denotes a new cluster descriptor block. The next word is the name of the cluster (in this example, _cartman_). The first line in the configuration is the head node. The first name is the external interface followed by a colon and then the internal interface (for example, an outside user can login to the cluster by ssh’ing to _cartman-head.mydomain.com_). If only one name is specified, then it is assumed to be both external and internal. Starting on the next line is the node definitions. Nodes can be either ranges or single machines. The above example uses ranges – node1 through node64. In the case of a node being offline, two tags are used: exclude and dead. exclude sets nodes offline that are declared in a range and dead indicates a single node declaration is dead. The below example declares 32 nodes in a range with several offline and then 4 more nodes listed singularly with 2 offline.

    cluster kenny {
      node0 #head node
      dead placeholder #change command line to 1 indexing
      node[1-32] #first set of nodes
      exclude 30 #offline nodes in the range
      exclude [5-10]
      node100 #single node definition
      dead node101 #offline node
      dead node102
      node103
    }

One other thing to note is the use of a place holder node. When specifying ranges on the command line a nodes position in the configuration file is relevant. Ranges on the command line are 0 indexed. For example, in the cartman cluster example (first example), node1 occupies position 0 which may not be very intuitive to a user. Putting a node offline in front of the real compute nodes changes the indexing of the C3 command line ranges. In the kenny cluster example (second example) node1 occupies position one.

For a more detailed example, see the *c3.conf* man page.

### 4.3.3 Specifying Ranges

Ranges can be specified in two ways, one as a range, and the other as a single node. Ranges are specified by the following format: _m-n_, where _m_ is a positive integer (including zero) and _n_ is a number larger than _m_. Single positions are just the position number. If discontinuous ranges are needed, each range must be separated by a ",". The range "0-5, 9, 11" would execute on positions 0, 1, 2, 3, 4, 5, 9, and 11 (nodes marked as _offline_ will not participate in execution).

There are two tools used to help manage keeping track of which nodes are at which position: cname(1) and cnum(1). cnum assumes that you know node names and want to know their position. cname takes a range argument and returns the node names at those positions (if no range is specified it assumes that you want all the nodes in the cluster). See their man pages for details of use.

*NOTE:* ranges begin at zero!

### 4.3.4 Machine Definitions

Machine definitions are what C3 uses to specify clusters and ranges on the command line. There are four cases a machine definition can take. First is that one is not specified at all. C3 will execute on all the nodes on the _default cluster_ in this case (the _default cluster_ is the first cluster in the configuration file). An example would be as follows:

    $ cexec ls -l

the second case is a range on the default cluster. This is in a form of _<:range>_. An example _cexec_ would be as follows:

    $ cexec :1-4,6 ls -l

This would execute ls on nodes 1, 2, 3, 4, and 6 of the default cluster. The third method is specifying a specific cluster. This takes the form of _<cluster name:>_. An example _cexec_ would be as follows:

    $ cexec cartman: ls -l

This would execute ls on every node in cluster cartman. The fourth (and final) way of specifying a machine definition would be a range on a specific cluster. This takes the form of _<cluster name:range>_. An example _cexec_ would be as follows:

    $ cexec cartman:2-4,10 ls -l

This would execute ls on nodes 2, 3, 4, and 10 on cluster cartman. These four methods can be mixed on a single command line. for example

    $ cexec :0-4 stan: kyle:1-5 ls -l

is a valid command. it would execute ls on nodes 0, 1, 2, 3, and 4 of the default cluster, all of  _stan_ and nodes 1, 2, 3, 4, and 5 of _kyle_ (the _stan_ and _kyle_ cluster configuration blocks are not shown here). In this way one could easily do things such as add a user to several clusters or read _/var/log/messages_ for an event across many clusters. See the _c3-range_ man page for more detail.

### 4.3.5 Other Considerations

In most cases, C3 has tried to mimic the standard Linux command it is based on. This is to make using the cluster as transparent as possible. One of the large differences is such as using the interactive options. Because one would not want to be asked yes or no multiple times for each node, C3 will only ask _once_ if the interactive option is specified. This is very important to remember if running commands such as "_crm --all -R /tmp/foo_" (recursively delete _/tmp/foo_ on every node in every cluster you have access too).

Multiple cluster uses do not necessarily need to be restricted by listing specific nodes; nodes can also be grouped based on role, essentially forming a meta-cluster. For example, if one wishes to separate out PBS server nodes for specific tasks, it is possible to create a cluster called _pbs-servers_ and only execute a given command on that cluster. It is also useful to separate nodes out based on things such as hardware (e.g., fast-ether/gig-ether), software (e.g., some nodes may have a specific compiler), or role (e.g., _pbs-servers_).

== 4.4 LAM == #LAM

Official website: http://www.lam-mpi.org/

License:
 Indiana University has the exclusive rights to license this product
 under the following license.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

 1) All redistributions of source code must retain the above
    copyright notice, the list of authors in the original source code,
    this list of conditions and the disclaimer listed in this license; 
 2) All redistributions in binary form must reproduce the above
    copyright notice, this list of conditions and the disclaimer listed
    in this license in the documentation and/or other materials
    provided with the distribution; 
 3) Any documentation included with all redistributions must include
    the following acknowledgement:

    "This product includes software developed at the Ohio
    Supercomputer Center at The Ohio State University, the University
    of Notre Dame and the Pervasive Technology Labs at Indiana
    University with original ideas contributed from Cornell
    University. For technical information contact Andrew Lumsdaine at
    the Pervasive Technology Labs at Indiana University.  For
    administrative and license questions contact the Indiana
    University Research and Technology Corporation at 351 West 10th
    St., Indianapolis, Indiana 46202, phone 317-274-5905, fax
    317-274-5902."

 Alternatively, this acknowledgement may appear in the software itself,
 and wherever such third-party acknowledgments normally appear.

 4) The name "LAM" or "LAM/MPI" shall not be used to endorse or promote
    products derived from this software without prior written
    permission from Indiana University.  For written permission, please
    contact Indiana University Advanced Research & Technology
    Institute.  
 5) Products derived from this software may not be called "LAM" or
    "LAM/MPI", nor may "LAM" or "LAM/MPI" appear in their name, without
    prior written permission of Indiana University Advanced Research &
    Technology Institute.  

 Indiana University provides no reassurances that the source code
 provided does not infringe the patent or any other intellectual
 property rights of any other entity.  Indiana University disclaims any
 liability to any recipient for claims brought by any other entity
 based on infringement of intellectual property rights or otherwise. 

 LICENSEE UNDERSTANDS THAT SOFTWARE IS PROVIDED "AS IS" FOR WHICH NO
 WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. INDIANA UNIVERSITY
 GIVES NO WARRANTIES AND MAKES NO REPRESENTATION THAT SOFTWARE IS FREE
 OF INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER PROPRIETARY
 RIGHTS.  INDIANA UNIVERSITY MAKES NO WARRANTIES THAT SOFTWARE IS FREE
 FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", OR
 OTHER HARMFUL CODE.  LICENSEE ASSUMES THE ENTIRE RISK AS TO THE
 PERFORMANCE OF SOFTWARE AND/OR ASSOCIATED MATERIALS, AND TO THE
 PERFORMANCE AND VALIDITY OF INFORMATION GENERATED USING SOFTWARE. 

 Indiana University has the exclusive rights to license this product
 under this license.

### 4.4.1 Overview

LAM (Local Area Multicomputer) is an MPI programming environment and development system for heterogeneous computers on a network. With LAM/MPI, a dedicated cluster or an existing network computing infrastructure can act as a single parallel computer. LAM/MPI is considered to be "cluster friendly," in that it offers daemon-based process startup/control as well as fast client-to-client message passing protocols. LAM/MPI can use TCP/IP and/or shared memory for message passing.

LAM features a full implementation of MPI-1, and much of MPI-2. Compliant applications are source code portable between LAM/MPI and any other implementation of MPI. In addition to providing a high-quality implementation of the MPI standard, LAM/MPI offers extensive monitoring capabilities to support debugging. Monitoring happens on two levels. First, LAM/MPI has the hooks to allow a snapshot of process and message status to be taken at any time during an application run. This snapshot includes all aspects of synchronization plus datatype maps/signatures, communicator group membership, and message contents (see the XMPI application on the main LAM web site). On the second level, the MPI library is instrumented to produce a cummulative record of communication, which can be visualized either at runtime or post-mortem.

### 4.4.2 Notes about OSCAR's LAM/MPI Setup

The OSCAR environment is able to have multiple MPI implementations installed simultaneously – see Section 2.8 (page 13) for a description of the switcher program. LAM/MPI is configured on OSCAR to use the Secure Shell (ssh) to initially start processes on remote nodes. Normally, using ssh requires each user to set up cryptographic keys before being able to execute commands on remote nodes with no password. The OSCAR setup process has already taken care of this step for you. Hence, the LAM command lamboot should work with no additional setup from the user. 

### 4.4.3 Setting up switcher to use LAM/MPI

In order to use LAM/MPI successfully, you must first ensure that switcher is set to use LAM/MPI. First, execute the following command:

    $ switcher mpi --show

If the result contains a line beginning with "default" followed by a string containing "lam" (e.g., "lam-7.0.6"), then you can skip the rest of this section. Otherwise, execute the following command:

    $ switcher mpi --list

This shows all the MPI implementations that are available. Choose one that contains the name "lam" (e.g., "lam-7.0.6") and run the following command:

    $ switcher mpi = lam-7.0.6

This will set all _future_ shells to use LAM/MPI. In order to guarantee that all of your login environments contain the proper setup to use LAM/MPI, it is probably safest to logout and log back in again. Doing so will guarantee that all of your interactive shells will have the LAM commands and man pages will be found (i.e., your _$PATH_ and _$MANPATH_ environment variables set properly for LAM/MPI). Hence, you will be able to execute commands such as "_mpirun_" and "_man lamboot_" without any additional setup.

### 4.4.4 General Usage

The general scheme of using LAM/MPI is as follows:

 * Use the _lamboot_ command to start up the LAM run-time environment (RTE) across a specified set of nodes. The _lamboot_ command takes a single argument: the filename of a hostfile containing a list of nodes to run on. For example:
 
    $ lamboot my_hostfile
     ```
    
     * Repeat the following steps as many times as necessary:
       * Use the MPI "wrapper" compilers (''mpicc'' for C programs, ''mpiCC'' for C++ programs, and ''mpif77'' for fortran programs) to compile your application. These wrapper compilers add in all the necessary compiler flags and then invoke the underlying "real" compiler. For example:
       ```
    mpicc myprogram.c -o myprogram
       ```
    
       * Use the ''mpirun'' command to launch your parallel application in the LAM RTE. For example:
       ```
    $ mpirun C myprogram
       ```
    
         The mpirun command has many options and arguments – see the man page and/or "mpirun -h" for more information.
    
       * If your parallel program fails ungracefully, use the lamclean command to "clean" the LAM RTE and guarantee to remove all instances of the running program.
    
       * Use the ''lamhalt'' command to shut down the LAM RTE. The ''lamhalt'' command takes no arguments.
    
    Note that the wrapper compilers are all set to use the corresponding GNU compilers (''gcc'', ''g++'', and ''gf77'', respectively). Attempting to use other compilers may run into difficulties because their linking styles may be different than what the LAM libraries expect (particularly for C++ and Fortran compilers).
    
    === 4.4.5 Other Resources ===
    
    The LAM/MPI web site ([http://www.lam-mpi.org/]) contains much, much more information about LAM/MPI, including:
     * A large Frequently Asked Questions (FAQ) list
     * Usage tutorials and examples
     * Access to the LAM user’s mailing list, including subscription instructions and web archives of the list
    
    Make today a LAM/MPI day!
    
    == 4.5 MPICH ==
    
    === 4.5.1 Overview ===
    
    Official Website: http://www-unix.mcs.anl.gov/mpi/mpich1/
    
    MPICH is another MPI implementation which is installed by OSCAR.  It is lighter weight than LAM/MPI and other implementations because it does not require any daemon processes to run on the compute nodes.  This has historically made it a popular choice with people doing benchmarking and production runs of well known codes.  It works in a very similar fashion to LAM/MPI but using mpirun requires an explicit list of nodes to be suplied at runtime, either from the command line or from a default file.
    
    MPICH example scripts sutable for a standard OSCAR install are included in the [#Torque Torque] scripting section.
    
    == 4.6 OpenMPI ==
    
    Official website: http://www.open-mpi.org/
    
    License: BSD
    
    == 4.7 The OSCAR Password Installer and User Management (OPIUM) == #OPIUM
    
    Official website: N/A.
    
    License: GPL v.2
    
    === 4.7.1 Overview ===
    
    The OPIUM package includes facilities which synchronize the cluster’s accounts and configures ssh for users. The user account synchronization may only be run by root, and is automatically triggered at regular intervals. OPIUM configures ssh such that every user can traverse the cluster securely without entering a password, once logged on to the head node. This is done using ssh user keys, in the .ssh folder in your home directory. It is not recommended that you make changes here unless you know what you are doing. If you change your password, make sure to change it on the OSCAR head node, because changes propagate to the cluster nodes from there.
    
    == 4.8 Packet Filtering with pfilter == #pFilter
    
    Official webiste: N/A.
    
    License: GPL v.2
    
    === 4.8.1 Overview ===
    
    When the pfilter packet filtering system is turned on, the default OSCAR settings allow any network communication between the machines in the cluster, and allow ssh and http access to the cluster main machine from the outside.
    
    Communication between cluster machines and the outside network are limited to outgoing connections only. Incoming network connections to cluster machines are blocked. To allow outside network connections to ports on the cluster machines, special rules will have to be added to the pfilter configuration. See your cluster administrator for help on this.
    
    == 4.9 PVM ==
    
    Official website: http://www.csm.ornl.gov/pvm/
    
    License: Freely distributable.
    
    === 4.9.1 Overview ===
    
    PVM (Parallel Virtual Machine) is a software package that permits a heterogeneous collection of Unix and/or Windows computers hooked together by a network to be used as a single large parallel computer. Thus large computational problems can be solved more cost effectively by using the aggregate power and memory of many computers. The software is very portable. The source, which is available free thru netlib, has been compiled on everything from laptops to CRAYs.
    
    PVM enables users to exploit their existing computer hardware to solve much larger problems at minimal additional cost. Hundreds of sites around the world are using PVM to solve important scientific, industrial, and medical problems in addition to PVM’s use as an educational tool to teach parallel programming. With tens of thousands of users, PVM has become the de facto standard for distributed computing world-wide.
    
    === 4.9.2 Using PVM ===
    
    The default OSCAR installation tests PVM via a Torque/PBS job (see also: Section 2.9 on page 18). However, some users may choose to use PVM outside of this context so a few words on usage may be helpful (the examples in this section assume a shared filesystem, as is used with OSCAR.)  The default location for user executables is $HOME/pvm3/bin/$PVM ARCH. On an IA-32 Linux machine, this is typically of the form: `/home/sgrundy/pvm3/bin/LINUX` (replace "LINUX" with "LINUX64" on IA-64). This is where binaries should be placed so that PVM can locate them when attempting to spawn tasks. This is detailed in the pvm intro(1PVM) manual page when discussing the environment variables PVM PATH and PVM WD.
    
    The "hello world" example shipped with PVM demonstrates how one can compile and run a simple application outside of Torque/PBS. The following screen log highlights this for a standard user sgrundy (Solomon Grundy).
    ```
    # Crate default directory for PVM binaries (one time operation)
    sgrundy: $ mkdir -p $HOME/pvm3/bin/$PVM_ARCH
    # Copy examples to local ’hello’ directory
    sgrundy: $ cp $PVM_ROOT/examples/hello* $HOME/hello-example
    sgrundy: $ cd $HOME/hello-example
    # Compile a hello world, using necessary include (-I) and library
    # (-L) search path info as well as the PVM3 lib.
    sgrundy: $ gcc -I$PVM_ROOT/include hello.c -L$PVM_ROOT/lib/$PVM_ARCH \
    > -lpvm3 -o hello
    sgrundy: $ gcc -I$PVM_ROOT/include hello_other.c -L$PVM_ROOT/lib/$PVM_ARCH \
    > -lpvm3 -o hello_other
    # Move the companion that will be spawned to the default
    # PVM searchable directory
    sgrundy: mv hello_other $HOME/pvm3/bin/$PVM_ARCH

At this point you can start PVM, add hosts to the virtual machine and run the application:

    # Start PVM and add one host "oscarnode1".
    sgrundy: $ pvm
    pvm> add oscarnode1
    add oscarnode1
    1 successful
                             HOST          DTID
                       oscarnode1         80000
    pvm> quit 
    quit
    
    Console: exit handler called
    pvmd still running.
    sgrundy: $
    
    # Run master portion of hello world which contacts the companion.
    sgrundy: $ ./hello
    i’m t40005
    from t80002: hello, world from oscarnode1.localdomain
    
    # Return to the PVM console and terminate (’halt’) the virtual machine.
    sgrundy: $
    sgrundy: $ pvm
    pvmd already running
    pvm> halt
    halt
    Terminated
    sgrundy: $

An alternate method is to use options in the hostfile supplied to pvm when started from the commandline. The advantage to the hostfile options is that you don’t have to place your binaries in the default location or edit any ".dot" files. You can compile and run the "hello world" example in this fashion by using a simple hostfile as shown here.

The example below uses the same "hello world" program that was previously compiled, but using a hostfile with the appropriate options to override the default execution and working directory. Remember that the "hello" program exists in the `/home/sgrundy/helloexample` directory:

    sgrumpy: $ cat myhostfile
    *   ep=/home/sgrundy/hello-example   wd=/home/sgrundy/hello-example
    oscarnode1

The options used here are:
 * * – any node can connect
 * ep – execution path, here set to local directory
 * wd – working directory, here set to local directory
 * _nodes_ – a list of nodes, one per line

Now, we can startup pvm using this _myhostfile_ and run the _hello_ application once again.

    # Now, we just pass this as an argument to PVM upon startup.
    sgrundy: $ pvm myhostfile
    pvm> quit
    quit
    Console: exit handler called
    pvmd still running.
    # The rest is the same as the previous example
    sgrundy: $ ./hello
    i’m t40005
    from t80002: hello, world from oscarnode1.localdomain
    sgrundy: $ pvm
    pvmd already running
    pvm> halt
    halt
    Terminated
    sgrundy: $

### 4.9.3 Resources

The OSCAR installation of PVM makes use of the env-switcher package (also see Section 2.8, page 13). This is where the system-wide $PVM_ROOT, $PVM_ARCH and $PVM_RSH environment variable defaults are set. Traditionally, this material was included in each user’s ".dot" files to ensure availability with noninteractive shells (e.g. rsh/ssh). Through the env-ewitcher package, a user can avoid any ".dot" file adjustments by using the hostfile directive or default paths for binaries as outlined in the Usage Section 2.6.1.

For additional information see also:
 * PVM web site: `http://www.csm.ornl.gov/pvm/`
 * Manual Pages: _pvm(1)_, _pvm intro(1)_, _pvmd3(1)_
 * Release docs: `$PVM_ROOT/doc/*`

== 4.10 System Installation Suite (SIS) == #SIS

Official websites
  SystemImager: http://wiki.systemimager.org/index.php/Main_Page
  SytemInstaller: http://wiki.systemimager.org/index.php/SystemInstaller
  SystemConfigurator: http://wiki.systemimager.org/index.php/System_Configurator

License: GPLv2 or later.

### 4.10.1 An overview of SIS

The System Installation Suite, or SIS, is a tool for installing Linux systems over a network. It is used in OSCAR to install the client nodes. SIS also provides the database from which OSCAR obtains its cluster configuration information. The main concept to understand about SIS is that it is an image based install tool. An image is basically a copy of all the files that get installed on a client. This image is stored on the server and can be accessed for customizations or updates. You can even chroot into the image and perform builds.

Once this image is built, clients are defined and associated with the image. When one of these clients boots using a SIS auto-install environment, either on floppy, CD, or through a network boot, the corresponding image is pulled over the network using rsync. Once the image is installed, it is customized with the hardware and networking information for that specific client and it is then rebooted. When booting the client will come up off the local disk and be ready to join the OSCAR cluster.

### 4.10.2 Building an Image

Normally, an OSCAR image is built using the <Build OSCAR Client Image> button on the OSCAR wizard. This button brings up a panel that is actually directly from the SIS GUI tksis. Once the information is filled in, the SIS command mksiimage is invoked to actually build the image.

In addition to building an image, you can use tksis or mksiimage to delete images as well. Images can take a fair amount of disk space, so if you end up with images that you aren’t using, you can delete them to recover some space.

### 4.10.3 Managing SIS Images

Much like the OSCAR image creation, the <Define OSCAR Clients> button actually invokes a tksis panel. There are a couple of SIS commands that are used to manage the client definitions. mksirange is used to define a group of clients. More importantly, mksimachine can be used to update client definitions. If, for example, you needed to change the MAC address after replacing one of your clients, you could use mksimachine.

### 4.10.4 Maintaining Client Software

There are many different ways to maintain the software installed on the client nodes. Since SIS is image based, it allows you to also use an image based maintenance scheme. Basically, you apply updates and patches to your images and then resync the clients to their respective images. Since rsync is used, only the actual data that has changed will be sent over the network to the client. The SIS command updateclient can be run on any client to initiate this update.

### 4.10.5 Additional Information

To obtain more detailed information about SIS, please refer to the many man pages that are shipped with SIS. Some of the more popular pages are:

 * tksis
 * mksiimage
 * mksidisk
 * mksirange
 * mksimachine
 * systemconfigurator
 * updateclient

You can also access the mailing lists and other docs through the sisuite home page, [http://sisuite.org/].

== 4.11 Switcher Environment Manager == #Switcher

Official website: N/A.

License: Freely distributable.

### 4.11.1 Overview

Experience has shown that requiring untrained users to manually edit their "dot" files (e.g., `$HOME/.bashrc,$HOME/.login`, `$HOME/.logout`, etc.) can result in damaged user environments. Side effects of damaged user environments include:

 * Lost and/or corrupted work
 * Severe frustration / dented furniture
 * Spending large amounts of time debugging "dot" files, both by the user and the system administrator

However, that it was a requirement for the OSCAR switcher package that advanced users should not be precluded - in any way - from either not using switcher, or otherwise satisfying their own advanced requirements without interference from switcher.

The OSCAR switcher package is an attempt to provide a simple mechanism to allow users to manipulate their environment. The switcher package provides a convenient command-line interface to manipulate the inclusion of packages in a user’s environment. Users are not required to manually edit their "dot" files, nor are they required to know what the inclusion of a given package in the environment entails.3 For example, if a user specifies that they want LAM/MPI in their environment, switcher will automatically add the appropriate entries to the $PATH and $MANPATH environment variables.

Finally, the OSCAR switcher package provides a two-level set of defaults: a system-level default and a user-level default. User-level defaults (if provided) override corresponding system-level defaults. This allows a system administrator to (for example) specify which MPI implementation users should have in their environment by setting the system-level default. Specific users, however, may decide that they want a different implementation in their environment and set their personal user-level default.

Note, however, that switcher does not change the environment of the shell from which it was invoked. This is a critical fact to remember when administrating your personal environment or the cluster. While this may seem inconvenient at first, switcher was specifically designed this way for two reasons:

 1. If a user inadvertantly damages their environment using switcher, there is still [potentially] a shell with an undamaged environment (i.e., the one that invoked switcher) that can be used to fix the problem.
 1. The switcher package uses the modules package for most of the actual environment manipulation (see `http://modules.sourceforge.net/`). The modules package can be used directly by users (or scripts) who wish to manipulate their current environment.

The OSCAR switcher package contains two sub-packages: modules and _env-switcher_. The modules package can be used by itself (usually for advanced users). The _env-switcher_ package provides a persistent modules-based environment.

### 4.11.2 The modules package

The modules package (see `http://modules.sourceforge.net/`) provides an elegant solution for individual packages to install (and uninstall) themselves from the current environment. Each OSCAR package can provide a modulefile that will set (or unset) relevant environment variables, create (or destroy) shell aliases, etc.

An OSCAR-ized modules RPM is installed during the OSCAR installation process. Installation of this RPM has the following notable effects:
 * Every user shell will be setup for modules - notably, the commands "module" and "man module" will work as expected.
 * Guarantee the execution of all modulefiles in a specific directory for every shell invocation (including corner cases such as non-interactive remote shell invocation by rsh/ssh).

Most users will not use any modules commands directly - they will only use the _env-switcher_ package. However, the modules package can be used directly by advanced users (and scripts).

### 4.11.3 The env-switcher package

The _env-switcher_ package provides a persistent modules-based environment. That is, _env-switcher_ ensures to load a consistent set of modules for each shell invocation (including corner cases such as non-interactive remote shells via rsh/ssh). _env-switcher_ is what allows users to manipulate their environment by using a simple command line interface - not by editing "dot" files.

It is important to note that _using the switcher command alters the environment of all *future* shells / user environments_. switcher does not change the environment of the shell from which it was invoked. This may seem seem inconvenient at first, but was done deliberately. See the rationale provided at the beginning of this section for the reasons why. If you’re really sure that you know what you’re doing, you can use the "switcher-reload" command after changing your switcher settings via the switcher command. This will change your current shell/environment to reflect your most recent switcher settings. 

_env-switcher_ manipulates four different kinds of entities: tags, attributes, and values.
 * Tags are used to group similar software packages. In OSCAR, for example, "mpi" is a commonly used tag.
 * Names are strings that indicate individual software package names in a tag.
 * Each tag can have zero or more attributes.
 * An attribute, if defined, must have a single value. An attribute specifies something about a given tag by having an assigned value.

There are a few built-in attributes with special meanings (any other attribute will be ignored by _env-switcher_, and can therefore be used to cache arbitrary values). "default" is probably the most-commonly used attribute - its value specifies which package will be loaded (as such, its value is always a name). For example, setting the "default" attribute on the "mpi" tag to a given value will control which MPI implementation is loaded into the environment.

_env-switcher_ operates at two different levels: system-level and user-level. The system-level tags, attributes, and values are stored in a central location. User-level tags, attributes, and values are stored in each user’s $HOME directory.

When _env-switcher_ looks up entity that it manipulates (for example, to determine the value of the "default" attribute on the "mpi" tag), it attempts to resolves the value in a specific sequence:
 1. Look for a "default" attribute value on the "mpi" tag in the user-level defaults
 1. Look for a "default" attribute value on the "global" tag in the user-level defaults
 1. Look for a "default" attribute value on the "mpi" tag in the system-level defaults
 1. Look for a "default" attribute value on the "global" tag in the system-level defaults

In this way, a four-tiered set of defaults can be effected: specific user-level, general user-level, specific system-level, and general system-level.

The most common _env-switcher_ commands that users will invoke are:
 * `switcher --list`
   List all available tags.
 * `switcher <tag> --list`
   List all defined attributes for the tag <tag>.
 * `switcher <tag> = <value> [--system]`
   A shortcut nomenclature to set the "default" attribute on <tag> equal to the value <value>. If the --system parameter is used, the change will affect the system-level defaults; otherwise, the user’s personal user-level defaults are changed.
 * `switcher <tag> --show`
   Show the all attribute / value pairs for the tag <tag>. The values shown will be for attributes that have a resolvable value (using the resolution sequence described above). Hence, this output may vary from user to user for a given <tag> depending on the values of user-level defaults.
 * `switcher <tag> --rm-attr <attr> [--system]`
   Remove the attribute <attr> from a given tag. If the --system parameter is used, the change will affect the system level defaults; otherwise, the user’s personal user-level defaults are used. Section 2.8.3 shows an example scenario using the switcher command detailing how to change which MPI implementation is used, both at the system-level and user-level. See the man page for switcher(1) and the output of switcher --help for more details on the switcher command.

### 4.11.4 Choosing a Default MPI

OSCAR has a generalized mechanism to both set a system-level default MPI implementation, and also to allow users to override the system-level default with their own choice of MPI implementation. This allows multiple MPI implementations to be installed on an OSCAR cluster (e.g., LAM/MPI and MPICH), yet still provide unambiguous MPI implementation selection for each user such that "mpicc foo.c -o foo" will give deterministic results.

### 4.11.5 Setting a system-level default

The system-level default MPI implementation can be set in two different (yet equivalent) ways:
 1. During the OSCAR installation, the GUI will prompt asking which MPI should be the system-level default. This will set the default for all users on the system who do not provide their own individual MPI settings.
 1. As root, execute the command:
 
    # switcher mpi --list
     ```
    
    This will list all the MPI implementations available. To set the system-level default, execute the command:
    ```
    # switcher mpi = name --system

where "name" is one of the names from the output of the --list command.

*NOTE:* System-level defaults for switcher are currently propogated to the nodes on a periodic basis. If you set the system-level MPI default, you will either need to wait until the next automatic "push" of configuration information, or manually execute the `/opt/sync files/bin/sync` files command to push the changes to the compute nodes.

*NOTE:* Using the switcher command to change the default MPI implementation will modify the PATH and MANPATH for all *future* shell invocations - it does not change the environment of the shell in which it was invoked. For example:

    # which mpicc
    /opt/lam-1.2.3/bin/mpicc
    # switcher mpi = mpich-4.5.6 --system
    # which mpicc
    /opt/lam-1.2.3/bin/mpicc
    # bash
    # which mpicc
    /opt/mpich-4.5.6/bin/mpicc

If you wish to have your current shell reflect the status of your switcher settings, you must run the "switcher-reload" command. For example:

    # which mpicc
    /opt/lam-1.2.3/bin/mpicc
    # switcher mpi = mpich-4.5.6 --system
    # which mpicc
    /opt/lam-1.2.3/bin/mpicc
    # switcher-reload
    # which mpicc
    /opt/mpich-4.5.6/bin/mpicc

Note that this is only necessary if you want to change your current environment. All new shells (including scripts) will automatically get the new switcher settings.

### 4.11.6 Setting a User Default

Setting a user-level default is essentially the same as setting the system-level default, except without the --system argument. This will set the user-level default instead of the system-level default:

    $ switcher mpi = lam-1.2.3

Using the special name none will indicate that no module should be loaded for the mpi tag. It is most often used by users to specify that they do not want a particular software package loaded.

    $ switcher mpi = none

Removing a user default (and therefore reverting to the system-level default) is done by removing the default attribute:

    $ switcher mpi --show
    user:default=mpich-1.2.4
    system:exists=true
    $ switcher mpi --rm-attr default
    $ switcher mpi --show
    system:default=lam-6.5.6
    system:exists=true

### 4.11.7 Use switcher with care!

switcher immediately affects the environment of all future shell invocations (including the environment of scripts). To get a full list of options available, read the switcher(1) man page, and/or run switcher --help.

