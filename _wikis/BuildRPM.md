---
layout: wiki
title: BuildRPM
meta: 
permalink: "wiki/BuildRPM"
category: wiki
---
<!-- Name: BuildRPM -->
<!-- Version: 13 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR Distribution Support > [Distro Support](DistroSupport)

### General RPM building nodes

When building RPMs for OSCAR on x86 hardware, we have agreed to build them with i686 optimization, i.e., run `rpmbuild` with the `--target i686` argument.

If possible, change your buildhost's hostname to something that is representative of the distribution you are building on, e.g., `rhel4u3-x86-64.ocg.org`.

### LAM/MPI

You need to make sure that TORQUE is installed as well, otherwise LAM/MPI will be built without the TM Interface.  We will add a specific `Requires` for TORQUE in the LAM/MPI spec file in the future.

For Fedora Core 4 and 5, you need to add the following argument for `rpmbuild`:


    --define "config_options FC=gfortran --with-tm=/opt/pbs"

If you wish to build XMPI (the LAM/MPI process viewer) then you will need the Trillium headers enabled, to do this add `--with-trillium` to the config options, thus:


    --define "config_options --with-trillium"

This option may be added into future official releases of LAM/MPI for OSCAR, in which case it will just be hard coded into the specification file.


### Open MPI

We currently build the RPM with the following options:


    rpmbuild -ba --define "oscar 1" \
      --define "_packager YOUR_NAME <YOUR_EMAIL>" \ 
      --define "_vendor OSCAR" \
      --define "configure_options --with-tm=/opt/pbs" openmpi-1.0.2.spec

with the TORQUE RPMs installed on the build system.

### Sun Grid Engine
The SGE RPM includes parallel environment integration with PVM - the integration requires that a program be built with PVM libraries and therefore rebuilding SGE requires PVM to be installed and to have the proper `PVM_ROOT` environment setup.  The easiest way is to install the PVM package that comes with OSCAR, although it would probably be a lot easier if you can simply build it with the PVM RPM which came with Linux distribution.
