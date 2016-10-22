---
layout: wiki
title: MSM
meta: 
permalink: "/wiki/MSM"
category: wiki
---
<!-- Name: MSM -->
<!-- Version: 5 -->
<!-- Author: wesbland -->

[Development Documentation](/wiki/DevelDocs/) > [Oscar Set Manager](/wiki/OSM/) > Machine Set Manager

# Machine Set Manager

The Machine Set Manager is a tool designed to divide up machines into groups.  This can be useful for example if certain packages should only be installed on certain nodes.  By taking advantage of the Machine Set Manager, dividing up the cluster into smaller sets is simple.

## Machine Set Definitions

The Machine Set definitions will be stored in an XML file using the [source:trunk/share/schemas/machineset.xsd schema] described in trunk.  The XML file will have a section for describing machines by their IP address and type and another section to describe machine sets.  The files should be located in trunk/share/machine_sets.  The default file should be called `defaultms.xml` but other machine set files can be placed in this directory and used via the _use_file_ function.

## Public API

The library is located at _lib/OSCAR/msm.pm_

 * _use_file ($file_name)_: Changes the file in use by the machine set manager from the default file (`defaultms.xml`) to a specified file.

 * _describe_set ($set_name)_: Returns a list of machines in a specified set.

 * _list_sets ()_: Returns a list of all the machine sets in the machine sets file.

 * _machine_type ($hostname)_: Gives the type of a specified machine.

 * _list_machines ()_: Returns a list of all the machines in the machine sets file.