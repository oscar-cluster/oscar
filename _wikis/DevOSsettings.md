---
layout: wiki
title: DevOSsettings
meta: 
permalink: "wiki/DevOSsettings"
category: wiki
---
<!-- Name: DevOSsettings -->
<!-- Version: 1 -->
<!-- Author: prg3 -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > [OCA](DevOCA)

## OS_Settings framework for normalizing os specific settings

The OCA::OS_Settings framework makes it easy and consistent to specify any OS/Distribution specific settings.  It uses configuration files to specify key/value pairs that can be extracted by using 
the getitem("value") function.

The configuration files are read in order from most generic through to most specific.  It will read all 
configuration options from the OS_Settings/default file, and proceed through $distro, $distro$version and $ident as defined by OS_Detect.  This allows for generic settings, which can be overridden by the subsequent configuration files.  


Basic and simplest usage:

    #!perl
      use lib "$ENV{OSCAR_HOME}/lib";
      use OSCAR::OCA::OS_Detect;
      use OSCAR::OCA::OS_Settings;
    
      $os = OSCAR::OCA::OS_Settings::getitem(nfs_package);

The result will be a value corresponding to the name of the nfs package as defined for your current OS.

This framework can be used anywhere, and adding key/value pairs are easy with any text editor.  
