---
layout: wiki
title: OscarReleaseTesting
meta: 
permalink: "wiki/OscarReleaseTesting"
category: wiki
---
<!-- Name: OscarReleaseTesting -->
<!-- Version: 7 -->
<!-- Author: naughtont -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > Testing

## Introduction

This page contains information about the basic testing procedures for OSCAR.  

Currently there are two types of tests in OSCAR:
 * Post installation tests -- these tests are run at the end of an OSCAR install
 * Internal/Infrastructure tests -- these are tests primarily used by developers 

Also, there is a basic "check list" that is available that outlines some _Required_
and _Optional_ tests that are to be performed when doing OSCAR testing (especially in
preparation for a release).  This check list is available in the code repository under
at [testing/oscar-testing.txt](https://svn.oscar.openclustergroup.org/svn/oscar/trunk/testing/oscar-testing.txt),

       <OSCAR_HOME>/testing/oscar-testing.txt

A tester should be able to edit this file during a test, save the results and post 
success/errors/warning details on the oscar-devel mailing list.


## Post installation tests

These tests are performed at the end of the OSCAR install and are driven by a top-level
script in the _testing/_ directory:

       <OSCAR_HOME>/testing/test_cluster

This script runs two forms of tests, privledged tests run as the _root_ user and non-privledged tests
run as a standard users _oscartst_ (which is created by the test_cluster script).  There is a pretty-print
script called _testprint_ that is used by this driver to help format the output.  

The driver script performs a few hardcoded tests (NFS mounts, etc.) and then walks over the various OSCAR
packages that have been installed running any tests they provide.  The recognized tests that an OSCAR Package
may provide are (_<OPKG_DIR>_ is the OSCAR package Directory):

      <OPKG_DIR>/testing/test_root
      <OPKG_DIR>/testing/test_user
Note, these two scripts may written in any language but must be executable.  

Additionally, there are tests that an OSCAR Package can provide that use the *APITest* tool.  This
tool uses and XML markup to describe the tests or batches of tests that should be performed.  These tests may leverage the more advanced test harness offered by APITest.  See below for further details
about writing APITests.  

The driver script recognizes two tests for OSCAR Packages that are run using APITest:

       <OPKG_DIR>/testing/install_tests.apb
       <OPKG_DIR>/testing/validation_tests.apb




## Internal/Infrastructure tests

There are a few internal tests that are used to check the OSCAR infrastructure.  These are located in the top-level 
testing directory,

        <OSCAR_HOME>/testing/

Currently, much work needs to be done in this area.  See the [README.testing](https://svn.oscar.openclustergroup.org/svn/oscar/trunk/testing/README.testing) file for further details.



## APITest Overview

The APITest package was developed by William McLendon at Sandia National Labs.  It is included as a core 
package with OSCAR.  The [APITest User's Guide](http://svn.oscar.openclustergroup.org/svn/oscar/trunk/packages/apitest/doc/APItest-userguide-1_0.pdf) is 
included with the package.  There are also examples available with APITest, which as of apitest-1.0.0-12 are 
available in the _/usr/share/doc/apitest/examples/_ directory.
There are also some simple examples in the current PVM package that is included with OSCAR under, [_<OSCAR_HOME>/packages/pvm/testing/_](https://svn.oscar.openclustergroup.org/svn/oscar/trunk/packages/pvm/testing).

There are two types of APITest test files: 
  * simple tests (*.apt), and 
  * batch tests (*.apb).  

The simple tests can be a simple command, or a script of multiple commands and a few other interesting things (see the manual).  The general idea is that these tests should be small and do one thing.  Then you can organize these small tests into batches that can have dependencies and ordering where APITest manages the ordering/exeuction.  
Therefore you can build more complex testing scenarios and deal with success or failure with further tests accordingly.




