---
layout: wiki
title: TipModules
meta: 
permalink: "wiki/TipModules"
category: wiki
---
<!-- Name: TipModules -->
<!-- Version: 1 -->
<!-- Author: jparpail -->

# OSCAR Modules

This was developed and tested on OSCAR 5.0 on a 30 node cluster of Dell PE1950's using RedHat Enterprise Linux AS 4 Update 4.  Your mileage may vary.

OSCAR uses a package called [Modules](http://modules.sourceforge.net), which is a sort of shell environment packaging system.

It is designed to dynamically load and unload parts of your PATH, MANPATH, and other environment variables on the fly.  This is a useful way to make system and user level defaults for different packages, such as what MPI implementation people want to use.  However it is also a nice place to store all your environment related changes in an organized and easy to find place.

OSCAR will load all the modules found in `/opt/modules/oscar-modules` whenever modules get loaded.  I assume this is mostly at boot and when people make new shells.

It will also unload them automatically, though I am not as clear on when that happens, or why.

If you want to make your own modules, just make a subdirectory of `/opt/modules/oscar-modules` (for example `/opt/modules/oscar-modules/genesis`) and then you add a flat file with the name indicating the version number of the software you are using.  Modules can do some spiffy things and intelligently handle multiple version numbers in the directory, but I haven't needed to use this yet so I have no idea how it works.

Here is an example, from my trivial module called "genesis"

`/opt/modules/oscar-modules/genesis/2.3`

    #%Module -*- tcl -*-
    #
    # Genesis modulefile for OSCAR clusters
    #
    
    proc ModulesHelp { } {
       puts stderr "\tThis module adds Genesis to the PATH, MANPATH, LD_LIBRARY_PATH and also sets up SGE_ROOT."
    }
      
    module-whatis   "Sets up the Genesis environment for an OSCAR cluster."
      
    append-path MANPATH /usr/local/genesis/man
    append-path PATH /usr/local/genesis

This module is automatically loaded when the next user logs in, along with the others in /opt/modules/oscar-modules

Also, after you do this you will probably need to do

    cd /opt/modules/oscar-modules
    cpush genesis
    cexec "module load genesis"

This will make the module available and loaded on all the nodes.
