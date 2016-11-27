---
layout: wiki
title: DevRMdetect
meta: 
permalink: "wiki/DevRMdetect"
c ategory: wiki
---
<!-- Name: DevRMdetect -->
<!-- Version: 5 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > [OCA](DevOCA)

## Resouce Manager Detection Framework (RM_Detect)

The RM_Detect Framework's goal is to abstract out the detection and usage of resource managers in OSCAR clusters.  Previously, OSCAR was tied specifically to OpenPBS/TORQUE as its sole resource manager but with the introduction of OSCAR 5.0, Sun Grid Engine (SGE) support was added and thus the need to have a framework to support different resource managers becomes necessary.

This framework was modelled heavily using [OS_Detect](DevOSdetect) as a template.  By default, there is only one component in `lib/OSCAR/OCA/RM_Detect` and that is `None.pm`.  This is the default component if no other components are present on the system.  The system will error out if no components are found (including `None.pm` or if more than one component is found (we do not support multiple resource managers installed at the same time).  Typically RM_Detect components will come with the resource manager package in the `scripts/` directory and the component will be copied to `lib/OSCAR/OCA/RM_Detect` during the `post_server_install` step of the package.

RM_Detect plays the largest role during the *Test Cluster Setup* phase of installation as the framework currently deals with the abstraction of testing of parallel libraries together with the resource managers.

The following is a code snippet from the SGE RM_Detect component:


    my $displayname = "SGE";
    my $test = "sge_test";
    my $jobscript = "sge_script";
    
    # First set of data
    
    our $id = {
        name => $displayname,
        pkg => $pkg,
        major => $xml_ref->{version}->{major},
        minor => $xml_ref->{version}->{minor},
        test => "$pkg_dir/testing/$test",
        jobscript => "$jobscript",
        gui => "qmon",
    };

 * `$displayname` is the short name of the resource manager, this will be the name used during testing, eg. `Open MPI [via SGE]`
 * `$test` is the name of the script for testing the resource manager, typically `<rm_name>_test`, eg. `sge_test`
 * `$jobscript` is the prefix of the rm-specific job script to be used to test parallel libraries.  By default, the system will search for a script called `rm_script.<pkg_name>` in the parallel library's package directory - this format is used if the script works for all known resource managers.  If it is not possible to write one script that works for all resource managers, then use the naming convention specified by the `$jobscript` variable.
 * `id->gui` is the name of the GUI for the specific resource manager - the idea is to plug this into the [OSCAR Wizard](OscarWizard) manage mode (not used currently)

### How do we use the RM_Detect Framework?
 
Currently it is not possible to use more than one resource manager at a time (which makes sense!). Therefore in order to know what is the current resource manager, you just need to use the following code:


    use OSCAR::OCA::RM_Detect;
    my $rmgr = OSCAR::OCA::RM_Detect::open();

In this example, the variable _$rmgr_ is the _id_ of the resource manager. It is therefore possible to access the name of the resource manager by _$rmgr->{name}_. Note that if no resource manager is available, the name is "None".
