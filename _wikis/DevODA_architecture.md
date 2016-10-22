---
layout: wiki
title: DevODA_architecture
meta: 
permalink: "/wiki/DevODA_architecture"
category: wiki
---
<!-- Name: DevODA_architecture -->
<!-- Version: 17 -->
<!-- Author: valleegr -->

[wiki/DevelDocs] > [ODA](/wiki/DevODA/) > Architecture

!!! WARNING: THIS DOCUMENT DOES NOT REFLECT THE LATEST MODIFICATION OF THE DATABASE SCHEMA !!!

## Architecture of ODA
The scheme is fundamentally simple, enabling easy maintenance.[[BR]]
The old ODA used the complicated Perl codes for the command line[[BR]]
interface, which is not really necessary for development in OSCAR. The[[BR]]
new version of ODA removes the command line interface and has provided[[BR]]
a Perl module interface for all interactions between the OSCAR[[BR]]
installer and ODA.[[BR]]

The Perl module for the new version of ODA allows the OSCAR[[BR]]
derived projects to add their new functionalities to the main ODA[[BR]]
modules so that they can directly interact with database without[[BR]]
fear of breaking any main frame of OSCAR. If necessary, each of these[[BR]]
projects can make their own ODA module for the specialized database[[BR]]
functionality.[[BR]]

Considering these aspects, the new version of the OSCAR database architecture[[BR]]
is shown at the first attachment.[[BR]]

## Database Schema
The OSCAR database tables are created based on the entity-relation (ER)[[BR]]
diagram shown at the second attachment.[[BR]]

The central entities of the ER diagram are `Nodes`,`Packages`, and `Groups`.[[BR]]
These three entities and their relations describe the heart of the database schema.[[BR]]

`Groups` essentially provides categorizations of nodes and packages.[[BR]]
For grouping of nodes, `Groups` typically includes the OSCAR server [[BR]]
(a group simply containing the OSCAR head node of a given cluster), OSCAR clients[[BR]]
(all the client nodes in a cluster), and images(one or more disk images that,[[BR]]
for management purposes, are treated like real nodes). On the other hand,[[BR]] 
the `Group_Packages` relation contains the package groups to represent[[BR]]
what packages are installed in a group. A default package group is setup and[[BR]]
the packages that belong to this group are installed in all the nodes.[[BR]]

The `Packages` entity is related to the `Nodes` and `Groups` entity.[[BR]]
The `Node_Package_Status` relation which comes from the relation of `Nodes`,[[BR]]
`Packages`, and `Status` entity displays the status of OSCAR packages that are[[BR]]
related to a given node, such as which packages are installed, will be installed,[[BR]]
or should be uninstalled on a node.[[BR]]

The `Nodes` entity contains not only all the basic node information but also[[BR]]
the keys to connect with the `Groups`, `Packages`, and `Clusters` entities.[[BR]]
For example, a Node named _oscarnode1_ may belong to a certain[[BR]]
group, _OSCAR server_ as well as the default cluster, _OSCAR_.[[BR]]
The packages installed on _oscarnode1_ are determined by the relation[[BR]]
`Group_Packages` which has the entries displaying that _Default_ group[[BR]]
contains these packages. The _oscarnode1_ node may also have entries showing[[BR]]
that the Ganglia and PVM packages are successfully installed, that the TORQUE[[BR]]
package will be installed in the future, and that the PBS package should be uninstalled.[[BR]]

As described above, the relation among `Groups`, `Nodes`, and `Packages` is[[BR]]
designed to describe the installation status of packages on a given node, [[BR]]
what packages belong to what groups and which nodes are associated with a certain group.[[BR]]
This meta grouping allows the configuration of one or more nodes.  For example,[[BR]]
installing/uninstalling packages to certain nodes can be controlled precisely by[[BR]]
the relation among `Nodes`, `Groups`, and `Packages`.[[BR]]
`Status` entity and `Node_Package_Status` relation which connects[[BR]]
Nodes, Packages, and Status entity are designed for OSCAR Packages Manager[[BR]]
(OPM). The `Status` entity and `Node_Package_Status` are needed to[[BR]]
keep track of the status of installation of each of the OSCAR packages[[BR]] 
on the specific node.[[BR]]
----
 * [oda.pm](/wiki/DevODA_oda.pm/)
 * [Database.pm](/wiki/DevODA_Database.pm/)
 * [Maintenance](/wiki/DevODA_maintenance/) of ODA
 * [Database Schema](http://svn.oscar.openclustergroup.org/trac/oscar/export/7368/pkgsrc/oda/trunk/doc/oscar_oda.svg)