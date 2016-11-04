---
layout: wiki
title: BuildOpkg
meta: 
permalink: "wiki/BuildOpkg"
category: wiki
---
<!-- Name: BuildOpkg -->
<!-- Version: 5 -->
<!-- Author: jparpail -->

# How to build an OSCAR package (opkg)

The goals of the OSCAR package system is to describe software:
 * in a distribution-indepedant way,
 * with cluster-wide actions.

An _opkg_ description is made of a _config.xml_ file plus some others files (pre|post)-install scripts. Have a look at [opkgAPI] to get a full description of _opkg_ packaging.

_opkg_ description is compiled with [opkg_opkgc] to produce native packages (means _RPM_ or _.deb_).

# How to build an OSCAR Package (old way)

Building an OSCAR Package is easier than you think.  A package is composed of the following components:

 * binary package(s): RPM, deb, tarball
 * scripts for execution at various cluster installation steps: post_server_install, post_install
 * config.xml: contains meta information regarding the package eg. author of package, extra package dependencies
 * documentation: installation/user documentation

More information is available in the [OSCAR Package HOWTO](http://oscar.openclustergroup.org/public/docs/devel/oscarpkg-howto_22jan04.pdf) - it is a bit dated but still serves as a good primer explaining the general idea of what an OSCAR Package (opkg) is. It is useful for understanding the API scripts, when they get called and why.
_[EF: the HOWTO content should move to some wiki pages, it will be easier to keep updated]_


## __Important Notes__

### config.xml
The `config.xml` file structure has changed in trunk, i.e. for OSCAR 5.0. The new format is documented on the [ConfigXML] page.  A script to convert from the pre-5.0 format to 5.0+ format is available here: [browser:trunk/scripts/config-xml-convert.pl].

### generic-setup package structure
The `RPMS` directory is not used any more. Instead, each package needs to follow the [generic-setup](GenericSetup) structure. Starting with OSCAR 5.0 the wizard calls `generic-setup` for copying binary packages to `/tftpboot/oscar/*`. The `scripts/setup` script doesn't need to take care of this any more.
