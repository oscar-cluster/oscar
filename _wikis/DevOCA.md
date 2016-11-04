---
layout: wiki
title: DevOCA
meta: 
permalink: "wiki/DevOCA"
category: wiki
---
<!-- Name: DevOCA -->
<!-- Version: 7 -->
<!-- Author: bli -->

[Developer Documentation](DevelDocs) > OSCAR Component Architecture
## 

*Introduction*

The OSCAR toolkit has two primary advantages when compared with other popular cluster management suites: (i) supports a large set of Linux distributions, and (ii) provides an extensible packaging mechanism which eases the integration of new software into the OSCAR suite.

The OSCAR packaging mechanism bundles: application, reasonable default configurations, unit and system tests, and documentation, all of which are installed onto a user's cluster.  This enables a user to build a working cluster by following a sequence of basic steps, and a developer to extend the existing OSCAR suite for customized "spin-off" editions, e.g., HA-OSCAR, SSS-OSCAR and SSI-OSCAR.

The decoupling of applications from the core infrastructure is a crucial asset.  However, the current monolithic design of OSCAR's internal infrastructure hinders the long-term usefulness of the packaging mechanism (and OSCAR as a whole). *The core of the OSCAR suite is still very tightly coupled*.

For example, when extending OSCAR to support a new Linux distribution, the current design does not isolate distribution specific details. Therefore, in order to extend the supported distribution set, a developer may have to modify large portions of the OSCAR code base.  These changes would be better isolated with a more modular approach, with smaller modifications that are easier to manage.  Additionally, a modular design helps reduce the effects
to the overall system, so the addition or removal of components has limited impact and can be tested more easily.

Therefore, a component-based approach to software development will bolster the adaptability and help with development and maintenance. 

*Implementation Details*

All the frameworks are in the directory `lib/OSCAR/OCA`, in a specific directory. Each framework has a driver and at least one component. A component is a specific Perl module in the framework directory.

For instance, imagine we have the following system: 2 frameworks, _framework1_ and _framework2_; the framework1 has one component called _component1_; the framework2 has 2 components, respectively called _component2-1_ and _component2-2_.
Then, we will have the following organization:

    lib/OSCAR/OCA/framework1/
    lib/OSCAR/OCA/framework1.pm  (the driver)
    lib/OSCAR/OCA/framework1/component1.pm  (a component)
    lib/OSCAR/OCA/framework2/
    lib/OSCAR/OCA/framework2.pm (the driver)
    lib/OSCAR/OCA/framework2/component2-1.pm  (a component)
    lib/OSCAR/OCA/framework2/component2-2.pm  (a component)

*Testing/Debug*

A driver for OCA is available at [browser:trunk/scripts/OCA-driver.pl] which will output the information collected by the frameworks when executed.  For example, if the script is run on Fedora Core 6 x86, you will get the following output:


    [root@fc6-x86 scripts]# export OSCAR_HOME=<path_to_oscar_checkout_or_dir>
    [root@fc6-x86 scripts]# ./OCA-driver.pl 
    
    =============================================================================
    == OS_Detect
    =============================================================================
    
    -->  Dump...
    $VAR1 = {
              'compat_distro' => 'fc',
              'distro' => 'fedora',
              'chroot' => '/',
              'arch' => 'i386',
              'ident' => 'linux-i386-fedora-6',
              'os' => 'linux',
              'compat_distrover' => '6',
              'pkg' => 'rpm',
              'distro_version' => '6'
            };
    
    --> distro_flavor=()
    --> distro_version=(6)
    --> arch=(i386)
    
    =============================================================================
    == RM_Detect
    =============================================================================
    
    -->  Dump...
    $VAR1 = 1;
