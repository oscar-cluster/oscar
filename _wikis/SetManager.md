---
layout: wiki
title: SetManager
meta: 
permalink: "wiki/SetManager"
category: wiki
---
<!-- Name: SetManager -->
<!-- Version: 15 -->
<!-- Author: wesbland -->

[Development Documentation](wiki/DevelDocs) > [Oscar Set Manager](wiki/OSM) > Package Set Manager

# Package Set Manager

The Package Set Manager is a tool that has the ability to manage package sets and some limited repository management (by calling into opd2).  The result of the tool will be a set of OPKGs to be installed at a later time.  Configuration for the package may be added into the XML schema later.

## Manage Repositories

Using [OPD2](wiki/DevOPD2) the Package Set Manager will have the ability to add repositories and keep track of what packages are available in each repository.

## Manage Package Set Descriptions

The core of the Package Set Manager are the descriptions of the actual package sets.  The descriptions are in XML format which is shown in the [source:trunk/share/schemas/pkgset.xsd schema] file in trunk.  *The package sets should be stored in the directory `trunk/share/package_sets`.*  Directories can be placed underneath this for easier organization (i.e. Default).  For more information about how the descriptions should be formed, see this [source:trunk/src/pkg-set/README README] file.

These package sets can be combined inside the Package Set Manager along with individual packages to form a customized list of packages for a specific OSCAR installation.  The combination of these sets follows some rules:

  * If there is a dependency for a package, it will be added to the list of packages to install.
  * If there is a conflict, it will fall into one of two categories.
    * Resolvable conflicts
      * If the same package appears in multiple sets
        * If both requirements for the package are greater than, take the higher of the two requirements
        * If both requirements for the package are less than, take the lower of the two requirements
        * If both requirements are equal and not the same version number, an error results
        * If both requirements are equal and the same version number, pick one and continue
      * If no version of the package is specified, the default package will be installed by the installation tool
        * Most likely, this will be the newest package
      * For any other issue, the installation tool will pick the default package (noarch vs. arch)
    * Non resolvable conflicts
      * Two packages conflict with each other and are both selected results in an error

## OPKG Version Numbering

The OPKG version numbers will be compared using the same scheme as the dpkg version comparison.  The parser and comparison tool is borrowed from dpkg and converted to perl with some modifications to make parsing the versions out of XML easier.  A full description of how the OPKGs should be numbered is shown in the [OPKG Versioning](wiki/OPKGVersioning) document.

== OPKG Set Naming Scheme == 

The filename should be a short descriptive name for your package set that includes some other identifying information.  Use this rule to name your package set:
` short_description + '-' + distro + '-' + arch + '.xml' `

This makes it easy to find the exact package set desired and matches well with the name of the package set.

The name of your package set should be the same as the name of the file excluding the xml extension.

## Library API

The library is currently located at _lib/OSCAR/psm.pm_.

The public API is the following:

 * _select_set ($filename)_: Reads a file for the OPKG set (the file should have the same name as the OPKG set) and selects all the packages in the set.  The filename should give the location of the file relative to the directory `trunk/share/package_sets`.  For example, to use the default debian package set, the filename would be Default/debian-4-i386.xml.  Returns a string saying either 'OK' or giving a list of packages that could not be successfully selected.  If any packages are not successfully selected, then none of the packages are selected (no partial selections)

 * _select_opkg ($opkg_name)_: Adds an opkg to the list of selected packages.  Returns a string saying either 'OK' or an error message.

 * _unselect_opkg ($opkg_name)_: Removes an opkg from the list of selected packages.  Returns a string saying either 'OK' or an error message.

 * _clear_list ()_: Removes all packages from the list of packages to install

 * _export_list ($filename, [$name, $version, $distro, $distver, $arch])_: Exports the package set to the specified XML file.  As the local version will not have the name or version and possibly not distro and arch information, this information can be included as optional arguments.  Note that in order to use an argument, you must supply all the previous arguments.  This file is in a format that can be read back into the psm at a later time.

 * _show_list ()_: Returns an array containing the names of all the packages to be installed.

 * _describe_package_selection ($opkg_name)_: Returns a hash containing the description of the restrictions placed on a selected package.

 * _package_hash ()_: Returns the package list and any associated information in a format useful for the package install tool.
