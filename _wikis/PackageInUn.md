---
layout: wiki
title: PackageInUn
meta: 
permalink: "wiki/PackageInUn"
category: wiki
---
<!-- Name: PackageInUn -->
<!-- Version: 4 -->
<!-- Author: naughtont -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > OSCAR Packages

## PackageInUn

PackageInUn aims to provide an high-level interface for OSCAR package
installation/uninstallation. The current design is based on current features
provided by other OSCAR tools and library (yume for example).

For example, in the following graphs, `install packages` currently means
`yume-opkg install`. Of course that may change if OSCAR tools and library
are modified or extended.

PackageInUn also assume that all dependences between OSCAR packages are managed
by an higher-level tool. The idea is that a tool that may be called
PackageInUnDep finds dependences between OSCAR packages and then call in order
PackageInUn for each OSCAR package.

Furthermore, the interface for PackageInUn is still not finalized since the
OSCAR code does not allow today a full management of several images.

Figure 1 modelizes OSCAR package installation.

Figure 2 modelizes OSCAR package uninstallation.

Note that if an error occurs, the current interfaces (install/remove) do not
allow to go back to an stable state; interfaces such as install-force and
remove-force still have to be designed and implemented.


----

UPDATE: TJN - (10/20/2006) 

A bit more work on the flow, while looking to see what needs to be changed/added to the
existing OSCAR Database.

Two new figures have been attached, along with a Postscript document 
containing them (for easier printing).  They slightly refine the install process, giving
details for the database.  I believe that the current _Node_Package_Status_ table is sufficient 
for tracking the state during the install.  We will just need to add two new stages to the 
_Status_ table.  I have roughly been referring to those as: _install-bin-pkg_ and _run-scripts_.

Additionally, it appears that we track both compute-nodes and headnodes in the _Node_Package_Status_ table, 
but it appears we'll need to either extend this table, or probably just create another mapping that functions
exactly the same but is _Image_Package_Status_ to track the image/opkg/status.  (NOTE: Current semantics appear
to be that if an opkg is installed, it is on *all* images.  This is not the end design goal but the current
rule.)

Lastly, I have not yet generated the 3rd figure for the 'run-scripts' breakout (must transfer from the whiteboard :) ).



----

UPDATE: TJN - (10/23/2006)

I have no idea how to delete attachments in the Trac wiki, so I just uploaded a newer version of the Postscript (printer friendly) version that includes all the updated graphs.  The v1.3 postscript document is obsolete and can be ignored/deleted (if you know how). 
