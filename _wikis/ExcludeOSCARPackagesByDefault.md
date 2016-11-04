---
layout: wiki
title: ExcludeOSCARPackagesByDefault
meta: 
permalink: "wiki/ExcludeOSCARPackagesByDefault"
category: wiki
---
<!-- Name: ExcludeOSCARPackagesByDefault -->
<!-- Version: 6 -->
<!-- Author: jparpail -->

# Modification of the Default Package Set
# (AKA How to Exclude OSCAR Package from the Default Package Set)

## Overview

Since OSCAR supports several Linux distributions and a large set of OSCAR packages, it is possible that, for a specific release, some OSCAR packages are not supported on specific Linux distributions. In order to ease the user's life, a list of packages that have to be excluded may be defined for each Linux distribution.

## Implementation

The directory `share/package_set` may have files describing OSCAR packages that have to be excluded for specific Linux distribution. When OSCAR runs, a list of OSCAR packages is created. During this step, OSCAR checks if the directory `share/package_set` does not contain a file associated to the current distribution. 

For instance, on Debian-3 x86, OSCAR will check if the file `debian-3-i386.txt` exists. If the file exists, OSCAR reads the file and excludes all packages read from the file. If the file does not exist, only packages excluded by default (list in `script/populate_default_package_set`) are excluded.

The pattern of files in `share/package_set` is {distro}-{version}-{archi}.txt (e.g. fc-4-i386.txt). Each line of this file should give the name of a single OSCAR package.

In order to get the list of excluded OPKG, it is possible to use the function `get_excluded_opkg` provided by Package.pm.

## TODO

1/ The current implementation works only on the headnode, i.e., it is not possible to have different lists for the headnode and images. That has to be fixed.[[BR]]
2/ The current list of excluded OPKG is done via a text file, separated from OPKGs. However, the fact that an OPKG is not supported on a specific Linux distribution should be specified in the `config.xml` file.[[BR]]


