---
layout: wiki
title: ConfigFile
meta: 
permalink: "/wiki/ConfigFile"
category: wiki
---
<!-- Name: ConfigFile -->
<!-- Version: 2 -->
<!-- Author: valleegr -->

# OSCAR Configuration Files

## Overview

OSCAR aims to be "installed" in two different ways: (i) directly on the system (not using OSCAR_HOME), and (ii) continuing to use a single directory to host the OSCAR code (OSCAR_HOME), which directory is identified with the OSCAR_HOME environment variable (usefull when checking SVN code out and testing).

*Note that if the OSCAR_HOME environment variable is set, even if OSCAR is installed directly on the system, only the code in OSCAR_HOME should be used.*

To be able to deal with the two situations, configuration files are slowly introduced into OSCAR. The main OSCAR configuration file is _/etc/oscar/oscar.conf_. For the creation of such a configuration file, a template is available: 
http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/share/etc/templates/oscar.conf
It is possible to automatically generate a configuration, based on this template, using the _oscar-config_ script: _oscar-config --generate-config-file_.
For those how are still using OSCAR with the OSCAR_HOME environment variable, the configuration file will be created a way everything should transparently work. If you install OSCAR directly in the system, you may need to update the _/etc/oscar/oscar.conf_ file.

## Installation

To install the configuration files  from SVN sources directly into the system, simply execute the _make install_ command in the _$(OSCAR_HOME)/share_ directory.