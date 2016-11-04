---
layout: wiki
title: PvmTesting
meta: 
permalink: "wiki/PvmTesting"
category: wiki
---
<!-- Name: PvmTesting -->
<!-- Version: 2 -->
<!-- Author: bli -->

Here's a quick set of steps for testing PVM without having all of OSCAR installed.

 1. Install the PVM rpm(s) (_If you don't have Env-switcher/Modules installed you can set the following environment variables by hand on all systems to be used in the virtual machine, e.g., via $HOME/.profile (BASH) or the appropriate file for your shell._)

    # if on x86
       PVM_ARCH=LINUX
    # if on x86_64 or ia64
       PVM_ARCH=LINUX64
    PVM_ROOT=/opt/pvm3
    PVM_RSH=ssh
    PATH=$PATH:$PVM_ROOT/lib
    PATH=$PATH:$PVM_ROOT/lib/$PVM_ARCH
    PATH=$PATH:$PVM_ROOT/bin/$PVM_ARCH
 1. Grab the ['master1.c'](http://svn.oscar.openclustergroup.org/svn/oscar/trunk/packages/pvm/testing/master1.c) and ['slave1.c'](http://svn.oscar.openclustergroup.org/svn/oscar/trunk/packages/pvm/testing/slave1.c) files from the [testing/](http://svn.oscar.openclustergroup.org/svn/oscar/trunk/packages/pvm/testing) subdir of the PVM opkg.
 1. Compile the test programs,

      sgrundy: $ gcc -I$PVM_ROOT/include  master1.c \
                     -L$PVM_ROOT/lib/$PVM_ARCH -lpvm3 -o master1
    
      sgrundy: $ gcc -I$PVM_ROOT/include  slave1.c \
                     -L$PVM_ROOT/lib/$PVM_ARCH -lpvm3 -o slave1
  1. Create the default location for PVM binaries,

      sgrundy: $ mkdir -p $HOME/pvm3/bin/$PVM_ARCH
  1. Copy the 'master1' and 'slave1' files to the default PVM binaries location (see above),
```           
  sgrundy: $ cp master1 slave1 $HOME/pvm3/bin/$PVM_ARCH
```
  1. Startup pvm and add a machine (or two)

      sgrundy: $ pvm
      pvm> conf
           #...lists the current virtual machine configuration...
      pvm> add oscarnode1
      pvm> conf
           # ...lists the current virtual machine configuration...
 1. Exit from the pvm console using 'quit' (*not* 'halt').

       pvm> quit
       sgrundy: $
 1. Run the 'master1' binary and you should get results for the calculation. (_Assuming you have two nodes (localhost and oscarnode1) you would have 6 lines, three values from each machine._)
 1.You can now return to the pvm console and halt PVM to end the test.

      sgrundy: $ pvm
      pvm> halt


