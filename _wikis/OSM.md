---
layout: wiki
title: OSM
meta: 
permalink: "wiki/OSM"
category: wiki
---
<!-- Name: OSM -->
<!-- Version: 2 -->
<!-- Author: wesbland -->

[Development Documentation](DevelDocs) > OSCAR Set Manager

# OSCAR Set Manager (OSM)

The OSCAR Set Manager combines the functionality of the Package Set Manager (PSM) and the Machine Set Manager (MSM) into one tool that has the ability to describe a cluster installation at a very high level.  Using the OSCAR Set Manager, packages and package sets are placed onto machine sets by making a statement such as `Put package set mpi on machine set A`.  Then by combining many of these statements, a complex cluster installation can be completed relatively easity.

## Library API

  * _add_set ($pkgset_filename, [$machineset])_: Adds a set of packages specified in the passed in filename to the machines in the specified set.  If there is no machine set specified, the packages will be added onto all machines.

  * _add_opkg ($opkg, [$machineset])_: Adds a single OSCAR package to a specified set of machines.  If there is no machine set specified, the package will be added onto all machines.

  * _result ()_: Returns the result of the additions in a single hash which can be passed into a tool to actually install the packages.

## Extended Example

This is an example of using the PSM, MSM, and OSM together to setup a complex OSCAR cluster with relatively little work.

### Machine Set Definitions

First the machine sets need to be defined in an XML file.  For this example we will use 2 servers and 10 client nodes.  This is a simplified version of the definition.  For more details about the specific implementation of the machine sets XML file, see the [Machine Set Manager](MSM) wiki page.


    I want 2 servers:
      oscarserver1
      oscarserver2
    
    I want 10 clients:
      oscarnode1
      oscarnode2
      oscarnode3
      oscarnode4
      oscarnode5
      oscarnode6
      oscarnode7
      oscarnode8
      oscarnode9
      oscarnode10
    
    Group A:
      oscarserver1
      oscarnode1
      oscarnode2
      oscarnode3
      oscarnode4
      oscarnode5
    
    Group B:
      oscarserver2
      oscarnode6
      oscarnode7
      oscarnode8
      oscarnode9
      oscarnode10
    
    Group C:
      oscarserver1
      oscarserver2
      oscarnode1
      oscarnode2
      oscarnode6
      oscarnode7
    
    Group D:
      oscarnode2
      oscarnode4
      oscarnode6
      oscarnode8
      oscarnode10

### OPKG Set Definitions

Next the OPKG Sets need to be defined in an XML file.  For examples of this, see the trunk [source:trunk/src/OscarSets/pkgsetexample-fedora-6-i386.xml example] and the [Package Set Manager](SetManager) wiki page.

### OSM Functions

Finally, you use the OSCAR Set Manager to combine the other tools and create an installation.  Again, this is a simplified version.  See the API above for a more detailed description of how to use OSM.


    Put package set nfs-debian-4-i386.xml on machine set A
    Put package set torque-debian-4-i386.xml on machine set B
    Put package set mpi-debian-4-i386.xml on machine set C
    Put package set lam-debian-4-i386.xml on machine set D
    Put package set core-debian-4-i386.xml and xen-debian-4-i386.xml on all machines

OSM will take the previous statements and convert them into a more explicit set of instructions:


    Put sets core, xen, and nfs on oscarnode3 and oscarnode5
    Put sets core, xen, and torque on oscarnode9
    Put sets core, xen, nfs, and mpi on oscarserver1 and oscarnode1
    Put sets core, xen, torque, and mpi on oscarserver2 and oscarnode7
    Put sets core, xen, nfs, mpi, and lam on oscarnode2
    Put sets core, xen, torque, mpi, and lam on oscarnode6
    Put sets core, xen, nfs, and lam on oscarnode4
    Put sets core, xen, torque, and lam on oscarnode8 and oscarnode10

It will also combine the sets into one larger set and resolve any conflicts at the set level (different versions of the same package, see [PSM](SetManager)).

The result of all of this will be a hash that is ready to be passed into the installation tool.

### Resulting Hash

When the result function is called, it constructs a hash representation of each node.  The hash is constructed like this:


    'nodename' => {  # The name of the node being described
        'packages => [  # A list of all the packages that were added individually
            'package1',
            'package2'
            ],
        'spec' => {  # A description of the setup on this node
            'distro' => { # The linux distribution for the node 
                          # (should match the XML files)
                'version' => 'x',
                'name' => 'exampleDistro'
            }
            'arch' => 'i386',  # The architecture of the node
            'package' => {  # The list of all the package to be 
                            # installed on the node either from the 
                            # packages list above or the set files listed below
                'package1' => {  # An example package and restrictions
                    'compare' => 'eq',
                    'number' => '1'
                },
                'package2' => {},
                'package3' => {
                    'compare' => 'gt',
                    'number' => '2.5'
                }
            }
        }
        'sets' => [  # A list of all the package sets that were added to this node
            'exSet-exampleDistro-x.xml'
        ]
    }

There will be an entry in the hash for each node (server and client).  Some of these entries can and probably will be duplicates except for the node name, but they will be repeated because that is the way they are represented in ODA.
