---
layout: wiki
title: CreateRPM
meta: 
permalink: "wiki/CreateRPM"
category: wiki
---
<!-- Name: CreateRPM -->
<!-- Version: 4 -->
<!-- Author: bli -->

[Developer Documentation](wiki/DevelDocs) > How to create RPMs

If the OSCAR Package you are trying to create does not already come in RPM binary format, then you will need to build one from scratch.

There are not any specific guidelines regarding how to build a RPM for OSCAR (they are not any different from building for Fedora or SUSE).  We simply asked that you try your best to make the `spec` file as generic as possible such that it works on all our supported RPM-based distributions like Red Hat, Mandriva and SUSE.

Macroes such as `%if %{?suse_version:1}0` are useful to determine what distribution you are building on and provide logic for different "Requires".

The following are some good resources on how to build RPMs from scratch:

 * http://fedoraproject.orgwiki/Packaging/Guidelines?action=show&redirect=PackagingGuidelines
 * http://www.rpm.org/max-rpm/
 * IBM Packaging software with RPM (3 part series):
   * http://www.ibm.com/developerworks/linux/library/l-rpm1/
   * http://www.ibm.com/developerworks/linux/library/l-rpm2/
   * http://www.ibm.com/developerworks/linux/library/l-rpm3.html

### Do not build debuginfo package

If you do not wish to build the debuginfo package, put the following in your spec file:


    %define debug_package %{nil}
 
 
