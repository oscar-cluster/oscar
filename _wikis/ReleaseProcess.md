---
layout: wiki
title: ReleaseProcess
meta: 
permalink: "wiki/ReleaseProcess"
category: wiki
---
<!-- Name: ReleaseProcess -->
<!-- Version: 18 -->
<!-- Author: valleegr -->

[Developer Documentation](DevelDocs) > Release Processes

## Release Processes

1. Make sure to unit tests can run successfully (running [run_unit_test](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/testing/run_unit_test)).

2. Prepare documentations
  a. Write and update [Installation/Administration guide](Support) documentations accordingly.
  a. Generate the _Installation Manual_ PDF. For that, log into the OSCAR Trac system (https://svn.oscar.openclustergroup.org), and go under Admin->WikiToPdf, select the following pages and export to PDF: InstallGuideIntroduction, InstallGuideReleaseNotes, InstallGuidePreparing, InstallGuideNetwork, InstallGuideClusterInstall, InstallGuide/Appendices, InstallGuide/Appendices/NetworkBooting, InstallGuide/Appendices/SISBoot, InstallGuide/Appendices/Tips.
  a. Generate the _Management Manual_ PDF. For that, log into the OSCAR Trac system (https://svn.oscar.openclustergroup.org), and go under Admin->WikiToPdf, select the following pages and export to PDF: AdminGuide, AdminGuide/Introduction, AdminGuide/Wizard, AdminGuide/Commands, AdminGuide/Packages, AdminGuide/Licenses, AdminGuide/Licenses/C3, AdminGuide/Licenses/DisableService, AdminGuide/Licenses/LAM, AdminGuide/Licenses/Maui, AdminGuide/Licenses/MPICH, AdminGuide/Licenses/pFilter, AdminGuide/Licenses/PVM, AdminGuide/Licenses/SIS, AdminGuide/Licenses/Switcher, AdminGuide/Licenses/Torque.
  a. Write and update [release notes](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/dist/release-info).
  a. Put the pdf files and the release notes to the OSCAR SVN repository.
  a. In SVN, update the [VERSION file](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/VERSION).

3. Make sure the following updates are done:
  a. Update the [oscar-base.spec.in](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/oscar-base.spec.in) file (you may want to update the release number) and the Debian changelog (executing the _dch -v <oscar_version>_ command).
  a. Update the OSCAR [ChangeLog file](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/ChangeLog).
  a. Update the [list of supported distros](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/share/etc/supported_distros.txt).


4. Tag the working branch.
  a. Tag the current working branch to http://svn.oscar.openclustergroup.org/svn/oscar/tags
  a. The naming rule of the tag is "rel"-[VERSION_NUMBER]-[BETA_NUMBER]
    * [VERSION_NUMBER] is the version number of OSCAR that we are going to release and dash(-) would be used to connect the major version number and the minor version number[[BR]] (e.g., for OSCAR 5.1, it would be 5-1)
    * [BETA_NUMBER] is numbered beginning with "b" and followed by the number. The starting number is 1 and it increases one by one if we increases the beta number
  a. If everything seems to work fine on the beta tarball, another tag should be made without [BETA_NUMBER] in order to tag for the release version

4. Generate new binary packages for supported Linux distributions and upload them on the official OSCAR repositories.

5. Post announcements.
Email to the announce/devel lists to announce the release
