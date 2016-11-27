---
layout: wiki
title: DebugOSCAR
meta: 
permalink: "wiki/DebugOSCAR"
category: wiki
---
<!-- Name: DebugOSCAR -->
<!-- Version: 1 -->
<!-- Author: bli -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > Preparations

There are currently two environment variables that could be set prior to bringing up the OSCAR Wizard (i.e. initiating `install_cluster`):

 * `OSCAR_VERBOSE`
   * General verbosity on the console, yume, `install_prereq`

 * `DEBUG_OSCAR_WIZARD`
   * Debug messages for the OSCAR Wizard, button for re-starting wizard and dumping environment variables

These debugging options can be used by exporting them with a numerical value, i.e.:


    export OSCAR_VERBOSE=5

The greater the number, the higher the verbosity level.
