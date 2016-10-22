---
layout: wiki
title: Opkg
meta: 
permalink: "/wiki/Opkg"
category: wiki
---
<!-- Name: Opkg -->
<!-- Version: 3 -->
<!-- Author: valleegr -->

[Developer Documentation](/wiki/DevelDocs/) > Opkg

# How OPKGs are handled by OSCAR?

## Introduction

OSCAR users do not really have to care about how OSCAR internally deals with OSCAR packages but it is beneficial for developers to understand how OPKGs are handled by OSCAR. This document tries to give an high-level description and few pointers to clarify that.

## OPKG Description

Each OPKG is described by an XML file, the _config.xml_ file. This file describes the structure of a given OSCAR package. The description of the _config.xml_ file is out-of-scope of this document; specific documentation is available for that.
However, this file is used by OSCAR to populate the database, which is then used by other OSCAR components (i.e. every time we need to get information about a specific OPKG).

## OPKG Handling

Remember that all OPKG related data should be stored into the database. 

For instance, when you launch OSCAR, the following tasks are done:
1/ get the list of available OPKG via the _Default package set_ for the local Linux distribution,
2/ for each of these OPKGs, create the XML tree of the config.xml,
3/ call the _insert_packages_ function (from _lib/OSCAR/Database.pm_) which 
  a/ parse the XML tree to get data about the OPKG,
  b/ create the SQL command to include extracted data into the database.

It means that most of the work is currently done by the database related code; which means that the database code has to be updated if the XML schema for _config.xml_ files is modified.
It also means that for a component like OPD, which allows one to add OPKGs from remote repositories, the key function is _insert_packages_.

A function is also available to delete an OPKG from the database (function _delete_package_ from _lib/OSCAR/Database.pm_).

## OSCAR::Opkg

Currently there is only one function `opkg_print` which prepends `[package_name] ` to text which is printed by the function.  For instance:


    [sge] SGE post_install: Configuration SUCCESS on clients
    [sge] Post installation script executed successfully.

The OSCAR installation produces a lot of output and it is handy to print statements with this function so that you know which package a particular output belongs to.

In the future, the OSCAR::Opkg library should contain all the API function calls (eg. post_server_install, post_install) removing the need to keep separate scripts in each package's directory.

Not all package uses this API call yet - volunteers (see bug #[473](http://svn.oscar.openclustergroup.org/trac/oscar/ticket/473))?