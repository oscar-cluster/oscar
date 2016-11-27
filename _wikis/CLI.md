---
layout: wiki
title: CLI
meta: 
permalink: "wiki/CLI"
category: wiki
---
<!-- Name: CLI -->
<!-- Version: 21 -->
<!-- Author: wesbland -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure

[Development Documentation](DevelDocs) > Command Line Interface

## Command Line Interface

This Command Line Interface (CLI) for the OSCAR installer was written to facilitate faster and easier testing.  It also allows automation of cluster installation and makes recreating a cluster identical to a previous install very easy.  Most of the code to run these steps are housed in `src/cli/` with the exception of the code to setup the networking which is in `lib/OSCAR/MAC.pm`.  Also the top level installer `install_cluster` has been modified slightly so the user can use the command line installer.

As the installer runs, it writes a file with all the input the user gives that can be used to duplicate the install using the non-interactive installer.

To run the OSCAR installer in command line mode, run `install_cluster --cli <interface>`
If these flags are added, the script will run automatically:

    Usage: install_cluster [OPTION] adapter
    Starts the OSCAR install process.
    By default, install_cluster uses the Graphical mode.
    
        --cli                   Runs the program in command line mode.
        --opkgselector file     Passes the file into the selector stage of the install.
                                That stage will not ask for user input.
        --buildimage file       Passes the file into the build stage of the install.
                                That stage will not ask for user input.
        --defineclients file    Passes the file into the define clients stage of the install.
                                That stage will not ask for user input.
        --networkclients file   Passes the file into the setup network stage of the install.
                                That stage will not ask for user input.
        --help                  Display this help and exit.\n";
    

### Implementation Notes

    Step 0: Download Packages - Should be done with OPD command line.
    Step 1: [Selector](Selector)
    Step 2: [Configurator](Configurator)
     [configurator.html changes](Configurator.html)
    Step 3: [Install Server RPMs](InstallServer)
    Step 4: [Build Client Image](Build)
    Step 5: [Define OSCAR Clients](Define)
    Step 6: [Setup Networking](SetupNetwork)
    Step 7-8: [Complete and Test Cluster Setup](CompleteTest)
