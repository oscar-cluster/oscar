---
layout: wiki
title: SystemSanity
meta: 
permalink: "wiki/SystemSanity"
category: wiki
---
<!-- Name: SystemSanity -->
<!-- Version: 4 -->
<!-- Author: bli -->

# System Sanity Check

## Overview

System Sanity Check aims at and only at checking the system before the OSCAR actual initialization and but sure that the current system is suitable for the use of OSCAR.
Currently System Sanity checks if:
 * the user is logged as root,
 * selinux is not activated,
 * the network configuration is compliant with OSCAR,
 * the ssh configuration is compliant with OSCAR,
 * some APT configuration points for Debian-llike system.

== Implementation == 

The goal of System Sanity Check is to allows developers to easily develop new checking mechanisms for system checking. For that, System Sanity has been designed into two parts: (i) the driver (`$OSCAR_HOME/scripts/system-sanity`) and the folder to store all the scripts (`$OSCAR_HOME/scripts/system-sanity.d`).
When the driver is executed, it will automatically execute all the scripts present in `$OSCAR_HOME/scripts/system-sanity.d` (they are called modules). All the scripts will be executed even in case of an failure, a full report will be give to the user. In case of failures, the driver returns an error value.
On the other hand, modules have to be close to the following example:

    #!/usr/bin/perl
    # $Id$
    #
    
    use warnings;
    use English '-no_match_vars';
    use lib "$ENV{OSCAR_HOME}/lib";
    
    # NOTE: Use the predefined constants for consistency!
    use OSCAR::SystemSanity;
    
    my $rc = FAILURE;
    
    if ( <my_test> ) {
            $rc = SUCCESS;
    
    } elsif ( <my_test2> ) {
            print " ----------------------------------------------\n";
            print "  $0 \n";
            print "  WARNING: <my messages> \n";
            print " ----------------------------------------------\n";
    
            $rc = WARNING;
    } else {
            print " ----------------------------------------------\n";
            print "  $0 \n";
            print "  ERROR: <my messages> \n";
            print " ----------------------------------------------\n";
    
            $rc = FAILURE;
    }
    
    exit($rc);

Possible return values are:
 * 0 for SUCCESS,
 * 255 for FAILURE (based on shell behavior),
 * 1 to 254 for WARNING.

For the development of any new modules, the code just has to be compliant with the previous example and put into the `$OSCAR_HOME/scripts/system-sanity.d` folder.

## Sanity Check vs. Prereqs

EF said that it should be able to implement a system sanity mechanisms with the [prereqs](wiki/DevPrereqs) mechanism. Unfortunately when the System Sanity Check mechanism has been created at ORNL, the documentation on prereqs did not allow developers to be sure that prereqs meets the requirements and therefore whether or not it was possible to use it. And actually prereqs seems to be designed to perform actions (execute scripts, install/remove packages) and not to audit a system. For instance, it is not clear prereqs allows developers to develop easily new checking scripts returning FAILURE, SUCCESS or WARNING, guaranteeing that the mechanism will have the correct behavior (e.g. stop in case of failure).
But if prereqs meet the requirements for the implementation of a system sanity check mechanism, the current mechanism will have to be ported to the prereqs mechanism.
