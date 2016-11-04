---
layout: wiki
title: DevelRepositories
meta: 
permalink: "wiki/DevelRepositories"
category: wiki
---
<!-- Name: DevelRepositories -->
<!-- Version: 2 -->
<!-- Author: jparpail -->

# Repositories for Developers

## Developers Registration

Packages are hosted by the GForge service of INRIA. You have to be [registered](http://gforge.inria.fr/account/register.php) on this service.

Once registered, [add your public ssh (rsa or dsa) key](https://gforge.inria.fr/account/editsshkeys.php) and ask to join the [OSCAR project](https://gforge.inria.fr/projects/oscar). You will then be able to upload packages.

From the *oscar* project page of GForge, subscribe to `oscar-package` maillist to receive notifications of uploaded packages.

## Package authentication

Packages must be signed with gpg. The way it is done [depends on the packaging system](wiki/Packaging#PackageSignature) (.deb or RPM).

For packages to be accepted on repository, your gpg public key must be in the OSCAR keyring. For the moment, to add an identity into OSCAR keyring, please contact Jean Parpaillon.

## `opkg-upload`

To upload packages on both _yum_ or _apt_ *OSCAR* repositories, there is a unique tool called [browser:pkgsrc/opkg/trunk/opkg-upload opkg-upload].

Usage:


    opkg-upload --dist=dist1,dist2,etc packages

 * For RPM, packages is a list of .rpm files
 * For Debian, packages is a list of .changes files
 * packages must be either .changes or .rpm but not both
 * _--dist=help_ prints a list of supported distributions
