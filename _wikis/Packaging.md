---
layout: wiki
title: Packaging
meta: 
permalink: "wiki/Packaging"
category: wiki
---
<!-- Name: Packaging -->
<!-- Version: 4 -->
<!-- Author: bli -->

[[TOC]]

As a deployment tool, *OSCAR* heavily uses packaging systems. Currently, distributions supported by *OSCAR* are based on _RPM_ or _.deb_. Furthermore, software specifically packaged for *OSCAR* uses the _opkg_ packaging system.

## opkg packaging

_opkg_ system is specific to *OSCAR*. It allows developers to describe software with a cluster-wide view and in a multi-distribution way.

The _opkg_ description is then compiled with [opkgc](opkg_opkgc) to produce packages in distribution native systems (RPM or deb).

Here are useful resources about _opkg_ system:
 * [Describing a software with opkg](opkgAPI)
 * [The opkg compiler](opkg_opkgc)

## RPM packaging

RPM are used to package *OSCAR* core system itself. Furthermore, you may create OSCAR packages which depends on software which does not already come in RPM binary format.

There are not any specific guidelines regarding how to build a RPM for OSCAR (they are not any different from building for Fedora or SUSE).  We simply asked that you try your best to make the `spec` file as generic as possible such that it works on all our supported RPM-based distributions like Red Hat, Mandriva and SUSE.

Macroes such as `%if %{?suse_version:1}0` are useful to determine what distribution you are building on and provide logic for different "Requires".

The following are some good resources on how to build RPMs from scratch:

 * [Packaging Guidelines, by Fedora](http://fedoraproject.orgPackaging/Guidelines?action=show&redirect=PackagingGuidelines)
 * [RPM guide, by Fedora](http://docs.fedoraproject.org/drafts/rpm-guide-en)
 * [RPM HOW-TO (rpm.org)](http://www.rpm.org/support/RPM-HOWTO.html)
 * [Maximum RPM guide](http://www.rpm.org/max-rpm)
 * IBM Packaging software with RPM (3 part series):
   * [Introductory](http://www.ibm.com/developerworks/linux/library/l-rpm1)
   * [Building without root, patching software, and distributing RPMs](http://www.ibm.com/developerworks/linux/library/l-rpm2)
   * [Part 3](http://www.ibm.com/developerworks/linux/library/l-rpm3.html)
 * [Specific notes for building RPM for OSCAR](BuildRPM)

### Do not build debuginfo package

If you do not wish to build the debuginfo package, put the following in your spec file:


    %define debug_package %{nil}

## Debian packaging

As for RPM, you may use the Debian packaging system to describe *OSCAR* core system or to package third-part software which is not yet packaged in Debian.

Here are some useful resources:

 * Official documentation, heavy but complete:
   * [Debian Developer's Reference](http://www.debian.org/doc/developers-reference/index.html)
   * [Debian New Maintainers' Guide](http://www.debian.org/doc/manuals/maint-guide/index.html)
   * [Debian Policy Manual](http://www.debian.org/doc/debian-policy)
 * svn-buildpackage (maintaining packages with Subversion):
   * [http://workaround.org/moin/SvnBuildpackage]
   * [svn-buildpackage official documentation](http://www-user.rhrk.uni-kl.de/~blochedu/svn-docs/HOWTO.html)

### Specific notes for building Debian packages for *OSCAR*

#### Package validity

When uploading a Debian package on our repository, package validity is checked with the [lintian](http://lintian.debian.org) tool. We strongly advise you to check the package yourself before uploading it.

#### Distribution

Each changelog entry contains a space-separated list of distribution name this version is aimed to. Valid values are _stable_, _testing_ or _unstable_. Usually, Debian packages are written for _unstable_, and adapted to _stable_ if necessary.

See [Debian Policy Manual: Debian changelog](http://www.debian.org/doc/debian-policy/ch-source.html#s-dpkgchangelog) for more details.

#### Section

The _Section_ field in the _control_ files indicates an application area into which the package has been classified. For *OSCAR* packages (core packages or _opkg_ compiled into .deb), this section must be _oscar_. For other software (your updated package of _lam_, for instance), you must set _Section_ to extra.See  [Debian Policy Manual: Section field](http://www.debian.org/doc/debian-policy/ch-archive.html#s-subsections) for advanced details.

== Package signatures == #PackageSignature

All packaging systems allows developers to sign their packages. Then, we recommend to do it. If you don't yet have a GPG key, use:


    gpg --gen-key

and follow the instructions.

Useful resources: 
 * [GnuPG Mini howto](http://www.dewinter.com/gnupg_howto/english/GPGMiniHowto.html)
 * [Signing Built RPMs, by Fedora](http://docs.fedoraproject.org/drafts/rpm-guide-en/ch11s04.html)
 * [GnuPG Mini-HOWTO for Debian](http://www.infodrom.org/Debian/doc/gnupg.html) (mostly applicable to others)

## Package repositories

For instructions on uploading packages, have a look at [Repositories for Developers](DevelRepositories) page.

To get packages from repositories, have a look at [Repositories](Repositories) page.

To know how OSCAR package repositories are maintained see [Repositories Internals](RepositoriesInternals) page.

## Modification of the Default Package Set

Have a look at [How to exclude OSCAR package from the default package set](ExcludeOSCARPackagesByDefault)
