---
layout: wiki
title: DevOSdetect
meta: 
permalink: "wiki/DevOSdetect"
category: wiki
---
<!-- Name: DevOSdetect -->
<!-- Version: 7 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > [OCA](DevOCA)

## OS_Detect framework for detecting distributions

The OCA::OS_Detect eases the detection of the architecture and distribution. The initial implementation and first instance of the OCA framework aimed only at the detection of distro and architecture of the master node. The scope was extended for heterogeneous setups by [EF](ErichFocht), who added several methods for querying various targets. OS_Detect is now able to detect the distribution and architecture:
 * on the local node
 * inside an image (chroot)
 * of a local package pool

Basic and simplest usage:

    #!perl
      use lib "$ENV{OSCAR_HOME}/lib"; # Not necessary with oscar-6.x
      use OSCAR::OCA::OS_Detect;
    
      $os = OSCAR::OCA::OS_Detect::open();


The result of the call is a hash reference $os containing all available information about the distribution and the architecture:
|*_variable*_|*_description*_|*_example*_|
|`$id->{distro}`|real distribution name|redhat-el|
|`$id->{distro_version}`|distribution version number|4|
|`$id->{distro_update}`|distribution update number[[BR]] (where applicable)|2|
|`$id->{compat_distro}`|compatible distro name|rhel|
|`$id->{compat_distrover}`|compatible distro version|4|
|`$id->{arch}`|architecture (as reported by *uname -i*)|i386|
|`$id->{pkg}`|distro packaging method|rpm|

----

### Linux Distributions Specific Variable

#### Debian specific variables

|*_variable*_|*_description*_|*_example*_|
|`$i d->{codename}`|distribution codename, this data is mandatory for the management of many Debian related services|etch|
 
----


#### Other targets for distro detection

Detecting distro/arch in the chroot directory (image) $path:

    #!perl
      $os = OSCAR::OCA::OS_Detect::open(chroot=>$path);

Detecting distro/arch of a local package pool:

    #!perl
      $os = OSCAR::OCA::OS_Detect::open(pool=>$pool)


Build fake $os structure when the distro is known but the distro files are not accessible (e.g. for pools referenced by URLs):

    #!perl
      $os = OSCAR::OCA::OS_Detect::open(fake=>{
                                                distro=>$distro,
                                                distro_version=>$version,
                                                arch=>$arch
                                              }
                                        );
Main purpose: find compat distro and packaging method.
