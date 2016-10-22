---
layout: wiki
title: DevODA
meta: 
permalink: "/wiki/DevODA"
category: wiki
---
<!-- Name: DevODA -->
<!-- Version: 22 -->
<!-- Author: dikim -->

[wiki/DevelDocs] > ODA
## OSCAR Database API (ODA)

ODA is an OSCAR Database API to make it easy for users to use the OSCAR[[BR]]
database. When using ODA, there is no need to know how to connect the[[BR]]
database or determine what its schema look like. ODA deployed on the[[BR]]
OSCAR Subversion trunk uses Perl modules to connect, update, and query[[BR]]
the database. Also, all the database subroutines for the end users are[[BR]]
defined in a single Perl module, which is a collection of database[[BR]]
subroutines and does the intermediate work between back-end database[[BR]]
(e.g., MySQL) and OSCAR installation.

OSCAR installation is implemented by performing numerous[[BR]]
configurations to setup the order of installation and to install the[[BR]]
OSCAR packages.

*What can ODA do?*[[BR]]
These configurations are not only for setting up the OSCAR framework,[[BR]]
including a base library of internal functionality, but also for the[[BR]]
installation of OSCAR packages which are well known as an HPC tool. The[[BR]]
OSCAR framework is the main process of the OSCAR installation, which[[BR]]
makes the installer proceed from one step to the next. During[[BR]]
installation of OSCAR, the configurations need to be stored, queried,[[BR]]
and updated to manage the full OSCAR installation. ODA offers a place to[[BR]]
store the configurations and has been designed to query and update OSCAR[[BR]]
data, including the configurations resulting from installation.[[BR]]
In particular, ODA does the following:
  * Connects to the database with Perl DBI _perl_dbi_, which is the primary interface for database programming in Perl
  * Parses `config.xml` to convert into the SQL commands
  * Executes SQL query (select, create, update, delete, and so on)
  * Stores configurations
  * Stores installation status
  * Simplifies database queries
ODA is implemented with the two Perl modules: `oda.pm` and
`Database.pm`.
----
 * [oda.pm](/wiki/DevODA_oda.pm/)
 * [Database.pm](/wiki/DevODA_Database.pm/)
 * [Architecture](/wiki/DevODA_architecture/)
 * [Maintenance](/wiki/DevODA_maintenance/) of ODA