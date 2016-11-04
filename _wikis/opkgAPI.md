---
layout: wiki
title: opkgAPI
meta: 
permalink: "wiki/opkgAPI"
category: wiki
---
<!-- Name: opkgAPI -->
<!-- Version: 16 -->
<!-- Author: valleegr -->

# opkg API

## Quick _opkg_ overview

To describe a software with _opkg_, make a directory based on the package's name, e.g., `mypackage/`.
In it, create the following files/dir:

 * `config.xml` (see XML schema for structure [browser:pkgsrc/opkgc/trunk/doc/opkg.xsd config.xml schema])
 * (_Optional_) Creates (pre|post) install scripts in `scripts/` dir, as described in [#APIscripts Scripts section].
 * (_Optional_) Creates tests in `testing/` dir.
 * (_Optional_) Creates documentation in `doc/` dir.
 * Run `opkgc --dist=<your dist>` in this directory.

## config.xml

`config.xml` is the only required file for an OSCAR package. The [browser:pkgsrc/opkgc/trunk/doc/opkg.xsd config.xml schema] is used to check this file at compilation time.

 * `<name>` (_required_): the name of the package. This name is used to create RPM and deb packages so it must comply with their naming policy, which is: `[a-z0-9][a-z0-9+-\.]+`
 * `<class>`: defines which entity is responsible for the package and upstream code:
   * *core*: upstream code and package by OSCAR team;
   * *base*: upstream by third party, packaged by OSCAR team, core packages depend on it;
   * *included*: upstream by third party, packaged by OSCAR team, core packages do not depend on it;
   * *third-party*: upstream and package by third-party.
 * `<summary>` (_required_): a short description of the package (<= 80 chars)
 * `<description>`: a long description of the package. Paragraphs separated by empty line(s).
 * `<license>` (_required_): one of GPL, LGPL, PBS License, Freely distribuable, Maui license, BSD, SISSL
 * `<group>` (_required_, multiple occurrences allowed): application class (mpi, devel, admin, etc.)
 * `<uri>`: a link to a page which describes the package
 * `<authors>` (_required_): a list of `<author>` (at least one)
   * `<author>`: an author is described with a `<name>` (_required_), a `<nickname>`, an `<email>` (_required_), an `<institution>` and years of copyright given by a `<beginYear>` and a `<endYear>`. A required attribute `cat` specifies the author's responsibility: upstream, maintainer, uploader (for occasional work on the package).
 * `<filters>`: restricts the package to some distributions or some architectures. Contains list of `<dist>` and/or `<arch>`.
   * `<dist>`: contains the name of a distribution amongst: _debian_, _fc_, _sles_, _rhel_, _mdv_. Optional attributes *rel* and *version* (see above) can specify particular version(s) of the distro.
   * `<arch>`: contains an architecture to which the package is restricted. Can be _i386_, _amd64_, _x86_64_ or _ia64_.
 * `<serverDeps>`, `<clientDeps>`, `<apiDeps>`: contains dependencies with other packages for, respectively: _opkg-server-<name>_, _opkg-client-<name>_ and opkg-<name>'' package. Dependencies are made of 4 categories:
   * `<provides>`: this is the way to specify generic capacities offered by the package, such as _mpi_ or _batch-scheduler_. Have a look at distributions to see which are these existing virtual packages, or create your own.
   * `<conflicts>`: a list of packages this package conflicts with.
   * `<requires>`: packages this package depends on.
   * `<suggests>`: packages which are not required, but add functionnalities to your package. RPM system will ignore them.

 * `version`: is an attribute (used for `<pkg>` or `<dist>`) which specify a version
 * `rel`: is an attribute (used for `<pkg>` or `<dist>`) which is used with *version* to specify a range of version,  '<' and '>' are escaped because it's an XML document.
   * _&gt;_
   * _&gt;=_
   * _&lt;_
   * _&lt;=_

## API scripts

OPKG API scripts are supposed to configure the binary packages gathered in one OPKG in such a way that after the cluster installation they are set up correctly and ready to use. They should make use of the configuration options built into OSCAR (the configurator panel) and set up a sane configuration for the cluster even if the configurator was not used by the administrator.

With the switch to the new metapackages format and the opkg compiler (opkgc) the old API scripts have been renamed. The table below shows the new script name, with old name when if any:

| ___old name___          | ___new name___      | ___where exec___ | ___when exec___             | ___comment___ |
| _N/A_                   | api-pre-install       | master FS          | opkg-<name> pre-install       | |
| setup                     | api-post-install      | master FS          | opkg-<name> post-install      | |
| _N/A_                   | api-pre-uninstall     | master FS          | opkg-<name> pre-removal       | |
| _N/A_                   | api-post-uninstall    | master FS          | opkg-<name> post-removal      | |
| pre_configure             | api-pre-configure     | master FS          | Before launching configurator | Prepare data for configurator |
| post_configure            | api-post-configure    | master FS          | Returning from configurator   | Treat data from configurator |
| post_rpm_nochroot         | api-post-image        | master FS          | After image creation          | |
| post_clients              | api-post-clientdef    | master FS          | After defining clients        | |
| post_install              | api-post-deploy       | master FS          | After clients reboot          | |
| _N/A_                   | server-pre-install    | master FS          | opkg-server-<name> pre-install| |
| post_server_rpm_install   | server-post-install   | master FS          | opkg-server-<name> post-install| |
| _N/A_                   | server-pre-uninstall  | master FS          | opkg-server-<name> pre-removal     | |
| post_server_rpm_uninstall | server-post-uninstall | master FS          | opkg-server-<name> post-removal    | |
| _N/A_                   | client-pre-install    | chroot'ed image    | opkg-client-<name> pre-install     | |
| post_client_rpm_install   | client-post-install   | chroot'ed image    | opkg-client-<name> post-install    | |
| _N/A_                   | client-pre-uninstall  | chroot'ed image    | opkg-client-<name> pre-removal     | |
| post_client_rpm_uninstall | client-post-uninstall | chroot'ed image    | opkg-client-<name> post-removal    | |

_opkg_ being compiled into RPM are .deb packages, some scripts are executed by the RPM or dpkg system:
 * Scripts called _*-[pre|post]-[install|uninstall]_ are executed by RPM or dpkg system. For these ones, the exact semantic can be found on respective RPM or .deb documentation:
   * [Policy Manual: Package maintainer scripts and installation procedure](http://www.debian.org/doc/debian-policy/ch-maintainerscripts.html|Debian)]
   * [RPM Guide: Defining installation scripts](http://docs.fedoraproject.org/drafts/rpm-guide-en/ch09s04.html#id2972291|Fedora)

   I'm hearing you saying: "when I write my script, how can I know this is executed by RPM or dpkg ?". Here is the test you can do:
   ```
scriptname=$0
case $scriptname in
  *preinst|*postinst|*prerm|*postrm) 
    exec_by_dpkg $*
    ;;
  *rpm-tmp.*) 
    exec_by_rpm $*
    ;;
esac
   ```

   A full set of scripts are provided (see [#Example]) which let you easily understand how scripts are run by package management system, especially args passed to these scripts.

 * Other scripts are executed by OSCAR system.

### *-pre-install

These scripts are executed by RPM or dpkg before the package installation.

### *-post-install

These scripts are executed by RPM or dpkg after the package installation.

### *-pre-uninstall

These scripts are executed by RPM or dpkg before removing the package.

### *-post-uninstall

These scripts are executed by RPM or dpkg after removing the package.

### api-pre-configure

This script is run before launching the configurator interface. It is used to prepare data for the configurator.

 * Env: 
   * `OSCAR_PACKAGE_HOME`: script dirname
 * Place: `/var/lib/oscar/packages/<package>/api-pre-configure`

### api-post-configure

This script is run after configurator return. 

(Explain here how to get values from configurator)

 * Env:
   * `OSCAR_PACKAGE_HOME`: script dirname
 * Place: `/var/lib/oscar/packages/<package>/api-post-configure`

### api-post-image

This script is run on master node once image creation is finished.

 * Env:
   * `OSCAR_HOME`: path to _OSCAR_ base dir
 * Args:
   1. `IMAGEDIR`: path to chroot'able image

### api-post-clientdef

This script is run when clients are associated to an image.

 * Env:
   * `OSCAR_HOME`: path to _OSCAR_ base dir

### api-post-deploy

This script is run from the master node, once client nodes have been installed and restarted.

## Other scripts

All other files in `scripts/` dir are packaged in the _opkg-<name>_ package at: `/var/lib/oscar/packages/<name>`.

## Documentation

The `doc/` dir contains documentation of the OSCAR package. It is installed with _opkg-<name>_ package at: `/usr/share/doc/opkg-<name>/`.

## Testing

The testing framework runs `test_user` and `test_root` for each package where they exists. These scripts must be executable, anyway the language.
 * `test_user` is run as user `oscartst`
 * `test_root` is run as user `root`. _WARNING:_ as run by root, there are obvious security issues.

All files in the `testing/` dir are installed with _opkg-<name>_ package at: `/var/lib/oscar/testing/<name>`.

## Example

A full example of `opkg` is provided with the opkg compiler. If you installed `opkgc`, it is located into `/usr/share/doc/opkgc/samples`.

It is available online [browser:pkgsrc/opkgc/trunk/doc/samples here].

## Complete documentation

Complete documentation of the `opkg` format is available as a man page (`man opkg`) if you installed `opkgc`.

This manpage is available online [../browser/pkgsrc/opkgc/trunk/doc/opkg.5.html?format=raw here].
