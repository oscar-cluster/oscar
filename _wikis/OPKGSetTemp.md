---
layout: wiki
title: OPKGSetTemp
meta: 
permalink: "/wiki/OPKGSetTemp"
category: wiki
---
<!-- Name: OPKGSetTemp -->
<!-- Version: 2 -->
<!-- Author: naughtont -->

# Initial Implementation of Package Sets

OSCAR provides a basic notion of _package sets_, however the capability has never been fully implemented.  This document presents the current status for an initial implementation of _package sets_, which will be enhanced/extended by the more complete implementation being pursued by Wesley Bland ([Package Set Manager](/wiki/SetManager/)).

The current notion of a _Default Package Set_ has been implemented, which is used to exclude OPKGs on a given Linux distribution.


## Package Set Architecture

All package sets are defined in _$(OSCAR_HOME)/share/package_sets/_. In that directory a file describes a given package set for a specific Linux distribution and hardware architecture. They are organized as follow: ''$(OSCAR_HOME)/share/package_sets/<package_set_name>/<distro_name>-<distro_version>-<arch>.xml

This allows us to maintain different files for each Linux distribution.

The schema of the XML file describing a package set is shown here:


    <?xml version="1.0" encoding="ISO-8859-1"?>
    <package_set>
        <name>package_set_name</name>
        <packages>
            <opkg>opkg1_name</opkg>
            <opkg>other_opkg</opkg>
        </packages>
    </package_set>

## Default Package Set

OSCAR currently supports only one package set: the "Default" package set. This package set defines the set of OPKG(s) that are available, by default, in OSCAR for a specific Linux distribution.
For instance, the default package set for Debian Etch x86_64 is (filename: [source:trunk/share/package_sets/Default/debian-4-x86_64.xml debian-4-x86_64.xml]) :


    <?xml version="1.0" encoding="ISO-8859-1"?>
    <package_set>
        <name>Default</name>
        <packages>
            <opkg>base</opkg>
            <opkg>c3</opkg>
            <opkg>oda</opkg>
            <opkg>rapt</opkg>
            <opkg>sc3</opkg>
            <opkg>sis</opkg>
            <opkg>yume</opkg>
        </packages>
    </package_set>

The default package set is parsed by _$(OSCAR_HOME)/scripts/package_config_xmls_to_database_. 
