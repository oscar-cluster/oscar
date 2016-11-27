---
layout: wiki
title: DevPrereqs
meta: 
permalink: "wiki/DevPrereqs"
category: wiki
---
<!-- Name: DevPrereqs -->
<!-- Version: 1 -->
<!-- Author: efocht -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure

## Prerequisites

Prerequisites are conditions that have to be fulfilled such that the OSCAR wizard can do its job. Typical prerequisites are:
 * certain packages must be deleted from the system (for example tftp-server)
 * certain packages must be installed on the system
 * certain paths must exist
 * the distribution repository for the master node must exist

Prerequisites are distribution dependent! For example: yum is provided by certain distributions while it is missing on others, the mysql database packages are named differently, some distros come with needed perl modules while others don't.

Until (and including) OSCAR 4.2.1 the prerequisites handling was very static and controlled by the setup scripts in the `share/prereqs/*/scripts` directories. Adding support for new distributions was painful as it required the adaptation of each of these scripts. The prereq packages were not following the [generic-setup](GenericSetup) format which lead to chaos and confusion.

Starting with OSCAR 5.0 the prerequisites were reorganized by [EF](ErichFocht) to comply with the [generic-setup](GenericSetup) format. Their handling was integrated into the program `$OSCAR_HOME/scripts/install_prereq`.

### install_prereq

The program `$OSCAR_HOME/scripts/install_prereq` handles several tasks:
 * it detects the master node's distribution by using OCA::OS_Detect
 * it parses a distribution-aware configuration file `prereq.cfg` located in each prerequisite's top directory
 * follows the distro-specific instructions in the configuration file and
   * removes packages as specified in the configuration file
   * installs packages as specified in the configuration file
   * executes shell scripts as specified in the configuration file (not yet implemented [EF: April 26th, 2006])

The main task is the installation and removal of packages. `install_prereq` is geared towards using the [packman](DevPackman) smart installer features thus being able to resolve dependencies automatically from the package repositories. `install_prereq --smart` uses a packman instance specific to the current distro and expects that to return "true" when the `->is_smart()` method is invoked. It is able to resolve dependencies automatically from the
repositories.

As [packman](DevPackman) cannot be available right from the start on every distribution (because the underlying smart package managers like [yum(e)](DevYume) are not necessarilly installed), `install_prereq` has a _--dumb_ installation mode, where only the basic package managers are used for installing packages. Prerequisites installed in dumb mode need to provide all dependencies in their configuration file. The dumb mode is only used for bootstrapping the smart installer, i.e. for getting packman installed.


#### Configuration file: prereq.cfg

*_prereq.cfg*_

Each prerequisite must have a configuration file. This is called prereq.cfg and must be located in the top directory of the [generic-setup](GenericSetup) compatible prerequisites directory. Because prereqs are installed long before OSCAR is able to parse
[config.xml](ConfigXML) files, prereq.cfg is much simpler. The format is:


    [distro:version:architecture]
    package_name_or_rpm_file
    ...
    !package_name
    ...
    :bash: shell_command_or_script
    
    [distro2:version2:architecture2]
    ...
    
    # default
    [*:*:*]
    ...

The distro name, version or arch info can contain a "*". This matches
like a .* regexp.
Examples for distro headers:
[redhat-el*:3:*]::
  matches all rhel3 architectures.
[fedora:*:*]::
  matches all fedora core distros on all architectures
[mandr*:*:*]::
  matches both mandrake and mandriva
[*:*:*]::
  matches everything.

`Attention!` The real distro names are used here, not the compat names! This is because prerequisites are specific to the real distribution (CentOS is treated differently from RHEL), not the compatible distro names.

The lines after a distro identifier are package names or package file names
(without the full path info). One package/filename per line is allowed!
Lines starting with "!" specify packages which should be deleted. The lines
are executed in the order of appearance.

Processing of the prereq.cfg file stops after the parsing of the first
matching distro-block!


#### Usage


    
         install_prereq --dumb|--smart [--verbose] prereq_path
    
    
    Install prerequisites located in prereq_path. They should have the
    same directory structure like normal OSCAR packages but need to
    contain the configuration file prereq.cfg
    This file is required because prereqs are installed before
    config.xml files can be parsed.
    
    One of --smart|--dumb must be selected! --dumb installs packages
    listed in the prereq.cfg file with the base package manager and
    is unable to resolve dependencies. It should be used for
    bootstrapping a smart package manager. --smart installs prereqs
    with the help of a smart package manager like yum(e).
    The prereq_path arguments must be paths relative to the
    $OSCAR_HOME environment variable's value!

*_Usage in wizard_prep*_

The script which prepares for the installation wizard calls install_prereq two times:
 * `install_prereq --dumb` for bootstrapping the smart installer and dealing with the base prerequisites
 * `install_prereq --smart` for installing the prerequisites listed in the file
*$OSCAR_HOME/share/prereqs/prereqs.order* in smart mode.

Developers should not have to touch the `install_prereq --dumb` part except they need to add some new distro with support for another smart package manager.

Adding or modifying prerequisites should happen only by modifying the file *$OSCAR_HOME/share/prereqs/prereqs.order* and editing the prerequisites directories, themselves.
