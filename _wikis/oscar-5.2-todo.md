---
layout: wiki
title: oscar-5.2-todo
meta: 
permalink: "wiki/oscar-5.2-todo"
category: wiki
---
<!-- Name: oscar-5.2-todo -->
<!-- Version: 39 -->
<!-- Author: valleegr -->

# TODO List for OSCAR-5.2

This todo list is based on the audit performed by Weslay Bland. This audit is available [here](oscar5-1-audit)

1. Include binary packages available in branch and not available in trunk. For that, we will use online repositories in order to ease the management of those binary packages and also simplify the usage of OPKGC. This is why binary packages do not appear on that page. [WebORM](weborm) has been developed in order to provide a web-based interface for the creation and the management of OSCAR repositories. [WebORM](weborm) is still under testing and cannot be yet deployed in production mode (we also need to find a machine that can host both Debian and RPM repositories).

Status: [WebORM](weborm) under testing, upload complete for fc9-i386, fc9-x86_64, rhel5-i386, rhel5-x86_64, debian4-i386, and debian4-x86_64. The current URL of the server is http://bear.csm.ornl.gov/repos; but will change very soon (this is a temporary server).

2. Include the file representing the database schema, the associated API modifications (done).

3. Update the overall OSCAR code; after each file (the list is from the branch), you can see the current status if something has been done:


    .
    |-- COPYING                                                               [ok]
    |-- CREDITS                                                               [ok] 
    |-- Makefile                                                              [done]
    |-- README
    |-- RELEASE                                                               [N/A?]
    |-- VERSION                                                               [N/A]
    |-- debian                                                                [ok]
    |   |-- changelog                                                         [N/A] 
    |   |-- compat                                                            [ok]
    |   |-- control                                                           [ok]
    |   |-- copyright                                                         [ok]
    |   |-- patches                                                           [ok]
    |   |   |-- 01_image_path.patch                                           [ok]
    |   |   |-- 02_msm.patch                                                  [ok]
    |   |   |-- 03_psm.patch                                                  [ok]
    |   |   `-- 04_package_set.patch                                          [ok]
    |   `-- rules                                                             [ok]
    |-- dist                                                                  [ok]
    |   |-- Makefile.download                                                 [ok]
    |   |-- Makefile.options                                                  [ok]
    |   |-- beta-notice.txt                                                   [ok]
    |   |-- copyright-notice.txt                                              [ok]
    |   |-- insert-license.csh                                                [ok]
    |   |-- newmake.sh                                                        [done]
    |   |-- oscar-release.spec.in                                             [ok]
    |   |-- oscar.spec                                                        [ok]
    |   |-- programs.sh                                                       [ok]
    |   |-- release-info                                                      [ok]
    |   |   |-- checklist.txt                                                 [ok]
    |   |   |-- oscar-1.0-release.txt                                         [ok]
    |   |   |-- oscar-1.1-release.txt                                         [ok]
    |   |   |-- oscar-1.2.1-release.txt                                       [ok]
    |   |   |-- oscar-1.2beta-release.txt                                     [ok]
    |   |   |-- oscar-1.3beta-release.txt                                     [ok]
    |   |   |-- oscar-2.0-checklist.txt                                       [ok]
    |   |   |-- oscar-2.0-release.html                                        [ok]
    |   |   |-- oscar-2.0-release.txt                                         [ok]
    |   |   |-- oscar-2.2.1-checklist.txt                                     [ok]
    |   |   |-- oscar-2.2.1-release.html                                      [ok]
    |   |   |-- oscar-2.2.1-release.txt                                       [ok]
    |   |   |-- oscar-2.3.1-checklist.txt                                     [ok]
    |   |   |-- oscar-2.3.1-release.html                                      [ok]
    |   |   |-- oscar-2.3.1-release.txt                                       [ok]
    |   |   |-- oscar-4.0-release.html                                        [ok]
    |   |   |-- oscar-4.0-release.txt                                         [ok]
    |   |   |-- oscar-4.1-release.txt                                         [ok]
    |   |   |-- oscar-5.0-checklist.txt                                       [ok]
    |   |   |-- oscar-5.0-release.html                                        [ok]
    |   |   `-- oscar-5.0-release.txt                                         [ok]
    |   `-- update.sh                                                         [ok]
    |-- doc                                                                   [ok]
    |   |-- Makefile                                                          [ok]
    |   |-- Makefile.latex                                                    [ok]
    |   |-- OSCAR5.0_Install_Manual.pdf                                       [N/A]
    |   |-- OSCAR5.0_Users_Manual.pdf                                         [N/A]
    |   |-- README                                                            [ok]
    |   |-- architecture                                                      [ok]
    |   |   |-- Makefile                                                      [ok]
    |   |   |-- architecture.tex                                              [ok]
    |   |   |-- core-packages.tex                                             [ok]
    |   |   |-- defs.tex                                                      [ok]
    |   |   |-- design.tex                                                    [ok]
    |   |   |-- included-packages.tex                                         [ok]
    |   |   |-- intro.tex                                                     [ok]
    |   |   |-- oscar-1.tex                                                   [ok]
    |   |   |-- requirements.tex                                              [ok]
    |   |   |-- titlepage.tex                                                 [ok]
    |   |   |-- toc.tex                                                       [ok]
    |   |   `-- xml.tex                                                       [ok]
    |   |-- by-laws                                                           [ok]
    |   |   |-- Makefile                                                      [ok]
    |   |   |-- by-laws.tex                                                   [ok]
    |   |   |-- defs.tex                                                      [ok]
    |   |   |-- differences.tex                                               [ok]
    |   |   |-- intro.tex                                                     [ok]
    |   |   |-- titlepage.tex                                                 [ok]
    |   |   `-- toc.tex                                                       [ok]
    |   |-- development                                                       [ok]
    |   |   |-- Config-HOWTO.html                                             [ok]
    |   |   |-- Makefile                                                      [ok]
    |   |   |-- collaboration.tex                                             [ok]
    |   |   |-- core.tex                                                      [ok]
    |   |   |-- cvs.tex                                                       [ok]
    |   |   |-- defs.tex                                                      [ok]
    |   |   |-- development.tex                                               [ok]
    |   |   |-- directories.tex                                               [ok]
    |   |   |-- files.tex                                                     [ok]
    |   |   |-- intro.tex                                                     [ok]
    |   |   |-- provided_tools.tex                                            [ok]
    |   |   |-- release.tex                                                   [ok]
    |   |   |-- rpm_from_packages_splitted_in_distro_dependant_rpmlist.txt    [ok]
    |   |   |-- sourceforge.tex                                               [ok]
    |   |   |-- third-party.tex                                               [ok]
    |   |   |-- titlepage.tex                                                 [ok]
    |   |   |-- toc.tex                                                       [ok]
    |   |   `-- www.tex                                                       [ok]
    |   `-- oscarpkg-howto                                                    [ok]
    |       |-- Makefile                                                      [ok]
    |       |-- TODO                                                          [ok]
    |       |-- configurator.tex                                              [ok]
    |       |-- defs.tex                                                      [ok]
    |       |-- env-switcher.tex                                              [ok]
    |       |-- figs                                                          [ok]
    |       |   |-- Comments.png                                              [ok]
    |       |   |-- ConfiguratorExample.png                                   [ok]
    |       |   |-- EnableRootAccess.png                                      [ok]
    |       |   |-- EnterYourName.png                                         [ok]
    |       |   |-- EnterYourName2.png                                        [ok]
    |       |   |-- EnterYourPassword.png                                     [ok]
    |       |   |-- HiddenElement.png                                         [ok]
    |       |   |-- ResetForm.png                                             [ok]
    |       |   |-- SelectMachine.png                                         [ok]
    |       |   `-- UserType.png                                              [ok]
    |       |-- intro.tex                                                     [ok]
    |       |-- oda.tex                                                       [ok]
    |       |-- opd.tex                                                       [ok]
    |       |-- oscar-envvars-table.tex                                       [ok]
    |       |-- oscarpkg-howto.tex                                            [ok]
    |       |-- pkg-example.tex                                               [ok]
    |       |-- pkg-layout.tex                                                [ok]
    |       |-- pkg-scripts-table.tex                                         [ok]
    |       |-- pkg-xml-table.tex                                             [ok]
    |       `-- rules-of-thumb.tex                                            [ok]
    |-- images                                                                [ok]
    |   `-- oscar.gif                                                         [ok]
    |-- install_cluster                                                       [done]
    |-- lib                                                                   [done]
    |   |-- OSCAR                                                             [done]
    |   |   |-- AddNode.pm                                                    [ok]
    |   |   |-- CLI_MAC.pm                                                    [ok]
    |   |   |-- ClientMgt.pm                                                  [ok]
    |   |   |-- CmpVersions.pm                                                [ok]
    |   |   |-- ConfigFile.pm                                                 [done]
    |   |   |-- Configbox.pm                                                  [done]
    |   |   |-- Configurator.pm                                               [done]
    |   |   |-- Database.pm                                                   [done]
    |   |   |-- Database_generic.pm                                           [done]
    |   |   |-- DelNode.pm                                                    [done]
    |   |   |-- Distro.pm                                                     [done]
    |   |   |-- Env.pm                                                        [done]
    |   |   |-- FileUtils.pm                                                  [ok]
    |   |   |-- GUI_MAC.pm                                                    [ok]
    |   |   |-- Help.pm                                                       [ok]
    |   |   |-- ImageMgt.pm                                                   [N/A]
    |   |   |-- Logger.pm                                                     [ok]
    |   |   |-- MAC.pm                                                        [ok]
    |   |   |-- MACops.pm                                                     [ok]
    |   |   |-- Network.pm                                                    [ok]
    |   |   |-- NextIp.pm                                                     [ok]
    |   |   |-- OCA                                                           [done]
    |   |   |   |-- Debugger.pm                                               [ok]
    |   |   |   |-- OS_Detect                                                 [done]
    |   |   |   |   |-- CentOS.pm                                             [ok]
    |   |   |   |   |-- Debian.pm                                             [ok]
    |   |   |   |   |-- Fedora.pm                                             [done]
    |   |   |   |   |-- Mandriva.pm                                           [ok]
    |   |   |   |   |-- RedHat.pm                                             [ok]
    |   |   |   |   |-- SLES.pm                                               [ok]
    |   |   |   |   |-- ScientificLinux.pm                                    [ok]
    |   |   |   |   |-- SuSE.pm                                               [ok]
    |   |   |   |   `-- YDL.pm                                                [ok]
    |   |   |   |-- OS_Detect.pm                                              [ok]
    |   |   |   |-- RM_Detect                                                 [ok]
    |   |   |   |   `-- None.pm                                               [ok]
    |   |   |   |-- RM_Detect.pm                                              [ok]
    |   |   |   |-- Sanity_Check                                              [ok]
    |   |   |   |   |-- Images.pm                                             [ok]
    |   |   |   |   `-- OPKG.pm                                               [ok]
    |   |   |   `-- Sanity_Check.pm                                           [ok]
    |   |   |-- OCA.pm                                                        [ok]
    |   |   |-- ODA                                                           [done]
    |   |   |   |-- mysql.pm                                                  [done]
    |   |   |   `-- pgsql.pm                                                  [ok]
    |   |   |-- Opkg.pm                                                       [ok]
    |   |   |-- OpkgDB.pm                                                     [ok]
    |   |   |-- Package.pm                                                    [done]
    |   |   |-- PackageBest.pm                                                [ok]
    |   |   |-- PackageInUn.pm                                                [ok]
    |   |   |-- PackagePath.pm                                                [done]
    |   |   |-- PackageSet.pm                                                 [ok]
    |   |   |-- PackageSmart.pm                                               [ok]
    |   |   |-- PartitionMgt.pm                                               [ok]
    |   |   |-- SISBuildSetup.pm                                              [ok]
    |   |   |-- SwitcherAPI.pm                                                [ok]
    |   |   |-- SystemSanity.pm                                               [ok]
    |   |   |-- Tk.pm                                                         [ok]
    |   |   |-- Utils.pm                                                      [ok]
    |   |   |-- VersionParser.pm                                              [ok]
    |   |   |-- WizardEnv.pm                                                  [ok]
    |   |   |-- msm.pm                                                        [N/A]
    |   |   |-- opd2.pm                                                       [N/A]
    |   |   |-- osm.pm                                                        [N/A]
    |   |   `-- psm.pm                                                        [N/A]
    |   |-- Qt                                                                [done]
    |   |   |-- Opder.pl                                                      [ok]
    |   |   |-- OpderAbout.pm                                                 [ok]
    |   |   |-- OpderAddRepository.pm                                         [ok]
    |   |   |-- OpderDownloadInfo.pm                                          [ok]
    |   |   |-- OpderDownloadPackage.pm                                       [ok]
    |   |   |-- OpderImages.pm                                                [ok]
    |   |   |-- OpderTable.pm                                                 [ok]
    |   |   |-- Selector.pl                                                   [done]
    |   |   |-- SelectorAbout.pm                                              [ok]
    |   |   |-- SelectorCheckTableItem.pm                                     [ok]
    |   |   |-- SelectorImages.pm                                             [ok]
    |   |   |-- SelectorManageSets.pm                                         [done]
    |   |   |-- SelectorTable.pm                                              [done]
    |   |   |-- SelectorTableItem.pm                                          [ok]
    |   |   `-- SelectorUtils.pm                                              [done]
    |   `-- Tk                                                                [ok]
    |       |-- HTML                                                          [ok]
    |       |   |-- Form.pm                                                   [ok]
    |       |   |-- Handler.pm                                                [N/A]
    |       |   `-- IO.pm                                                     [ok]
    |       |-- HTML.pm                                                       [ok]
    |       `-- Web.pm                                                        [ok]
    |-- oscar-base.spec.in                                                    [done]
    |-- oscarsamples                                                          [done]
    |   |-- debian-4-i386.rpmlist                                             [ok]
    |   |-- debian-4-x86_64.rpmlist                                           [done]
    |   |-- fc-3-i386.rpmlist                                                 [ok]
    |   |-- fc-3-x86_64.rpmlist                                               [ok]
    |   |-- fc-4-i386.rpmlist                                                 [ok]
    |   |-- fc-4-x86_64.rpmlist                                               [ok]
    |   |-- fc-5-i386.rpmlist                                                 [ok]
    |   |-- fc-5-x86_64.rpmlist                                               [ok]
    |   |-- fc-6-i386.rpmlist                                                 [ok]
    |   |-- fc-7-i386.rpmlist                                                 [done]
    |   |-- fc-7-x86_64.rpmlist                                               [done]
    |   |-- fc-8-i386.rpmlist                                                 [done]
    |   |-- fc-8-x86_64.rpmlist                                               [done]
    |   |-- fc-9-x86_64.rpmlist                                               [done]
    |   |-- ide.disk                                                          [ok]
    |   |-- mdv-2006-i386.rpmlist                                             [ok]
    |   |-- rhel-3-i386.rpmlist                                               [ok]
    |   |-- rhel-3-ia64.rpmlist                                               [ok]
    |   |-- rhel-3-x86_64.rpmlist                                             [ok]
    |   |-- rhel-3u2-i386.rpmlist                                             [ok]
    |   |-- rhel-3u2-ia64.rpmlist                                             [ok]
    |   |-- rhel-4-i386.rpmlist                                               [ok]
    |   |-- rhel-4-ia64.rpmlist                                               [ok]
    |   |-- rhel-4-x86_64.rpmlist                                             [ok]
    |   |-- rhel-5-i386.rpmlist                                               [done]
    |   |-- rhel-5-x86_64.rpmlist                                             [done]
    |   |-- scsi.disk                                                         [ok]
    |   |-- scsi.ia64.disk                                                    [ok]
    |   |-- scsi.ppc64-ps3.disk                                               [done]
    |   |-- suse-10.0-i386.rpmlist                                            [ok]
    |   |-- suse-10.2-x86_64.rpmlist                                          [done]
    |   |-- suse-10.3-x86_64.rpmlist                                          [done]
    |   |-- swraid1-scsi.disk                                                 [ok]
    |   `-- ydl-5-ppc64.rpmlist                                               [done]
    |-- packages
    |   |-- apitest
    |   |   |-- SRPMS
    |   |   |   |-- README
    |   |   |   |-- apitest-1.0.0-12.2.src.rpm
    |   |   |   |-- build.cfg
    |   |   |   |-- python-elementtree-1.2.6-4.src.rpm
    |   |   |   `-- python-twisted-1.3.0-4ef.src.rpm
    |   |   |-- config.xml                                                    [done]
    |   |   |-- doc
    |   |   |   |-- APItest-userguide-1_0.pdf
    |   |   |   `-- install.tex
    |   |   `-- scripts
    |   |-- base
    |   |   |-- config.xml                                                     [ok]
    |   |   `-- scripts
    |   |       `-- api-post-image
    |   |-- c3
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- c3-4.0.1-5.src.rpm
    |   |   |-- config.xml                                        [done]
    |   |   |-- doc
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   `-- scripts
    |   |       |-- api-post-clientdef
    |   |       `-- post_buildimage
    |   |-- disable-services
    |   |   |-- config.xml                                         [ok]
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   `-- license.tex
    |   |   `-- scripts
    |   |       |-- api-post-image
    |   |       |-- disable.client.kudzu
    |   |       |-- disable.client.slocate
    |   |       `-- disable.client.whatis
    |   |-- documentation
    |   |   |-- SRPMS
    |   |   |   |-- oscar-install-docs-html-2.0b1-1.src.rpm
    |   |   |   `-- oscar-user-docs-html-2.0b1-1.src.rpm
    |   |   |-- config.xml                                                [done]
    |   |   |-- html
    |   |   |   `-- index.html
    |   |   `-- scripts
    |   |       |-- clean.sh
    |   |       |-- defs.sh
    |   |       `-- make_and_copy_doc.sh
    |   |-- ganglia
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   |-- ganglia-3.0.6-1.src.rpm
    |   |   |   |-- rrdtool-1.0.49-2.rf.src.rpm
    |   |   |   `-- rrdtool-1.2.11-1mdk.src.rpm
    |   |   |-- config.xml                                               [done]
    |   |   |-- configurator.html
    |   |   |-- configurator_image.html
    |   |   |-- doc
    |   |   |   |-- README
    |   |   |   `-- install.tex
    |   |   |-- scripts
    |   |   |   |-- api-post-image
    |   |   |   |-- edit_ganglia_conf
    |   |   |   |-- post_install
    |   |   |   `-- server-post-install
    |   |   `-- testing
    |   |       `-- test_user
    |   |-- jobmonarch
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   |-- jobmonarch-0.1.2-9.src.rpm
    |   |   |   `-- pbs_python-2.9.4-3.src.rpm
    |   |   |-- config.xml                                                          [done]
    |   |   |-- configurator.html
    |   |   `-- scripts
    |   |       `-- server-post_install
    |   |-- lam
    |   |   |-- SRPMS
    |   |   |   |-- README
    |   |   |   |-- build.cfg
    |   |   |   |-- lam-oscar-7.1.4-1.src.rpm
    |   |   |   `-- lam-switcher-modulefile-7.1.4-2.oscar.src.rpm
    |   |   |-- config.xml                                                        [done]
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   |-- scripts
    |   |   |   `-- client-post_install
    |   |   `-- testing
    |   |       |-- cpi.c
    |   |       |-- cxxhello.cc
    |   |       |-- f77hello.f
    |   |       |-- rm_script.lam
    |   |       `-- test_user
    |   |-- linux-ha
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- heartbeat-2.0.8-2ef.src.rpm
    |   |   |-- config.xml                                                        [ok]
    |   |   `-- scripts
    |   |-- loghost
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- loghost-1.0-1.src.rpm
    |   |   |-- config.xml                                                       [ok]
    |   |   `-- scripts
    |   |       `-- api-post-deploy
    |   |-- maui
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- maui-oscar-3.2.6p19-8.src.rpm
    |   |   |-- config.xml                                                       [ok]
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   |-- scripts
    |   |   |   |-- api-post-image
    |   |   |   `-- update_maui_config
    |   |   `-- testing
    |   |       `-- test_root
    |   |-- mpich
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- mpich-ch_p4-gcc-oscar-1.2.7-9.src.rpm
    |   |   |-- config.xml                                             [done]
    |   |   |-- doc
    |   |   |   `-- license.tex
    |   |   |-- scripts
    |   |   |   `-- api-post-clientdef
    |   |   `-- testing
    |   |       |-- cpi.c
    |   |       |-- cxxhello.cc
    |   |       |-- f77hello.f
    |   |       |-- rm_script.mpich
    |   |       `-- test_user
    |   |-- mta-config
    |   |   |-- config.xml                                               [ok]
    |   |   `-- scripts
    |   |       |-- api-post-deploy
    |   |       |-- enable.client.mail-locally
    |   |       |-- install_postfix
    |   |       `-- server-post-install
    |   |-- netbootmgr
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- netbootmgr-1.7-1.src.rpm
    |   |   |-- config.xml                                               [ok]
    |   |   `-- scripts
    |   |       |-- multi-arch-prepare
    |   |       `-- server-post-install
    |   |-- networking
    |   |   |-- config.xml                                             [done]
    |   |   |-- doc
    |   |   |   `-- install.tex
    |   |   `-- scripts
    |   |       |-- client-post_install
    |   |       `-- server-post_install
    |   |-- ntpconfig
    |   |   |-- config.xml                                              [ok]
    |   |   |-- configurator.html
    |   |   |-- doc
    |   |   |   `-- install.tex
    |   |   `-- scripts
    |   |       |-- api-post-deploy
    |   |       |-- client-post_install
    |   |       `-- server-post_install
    |   |-- oda
    |   |   |-- SRPMS
    |   |   |   `-- mysql-3.23.58-1.src.rpm
    |   |   |-- config.xml                                             [ok]
    |   |   |-- doc                                                    [ok]
    |   |   |   |-- oda-for-packages                                   [ok]
    |   |   |   |-- oda-pm                                             [ok]
    |   |   |   `-- oda-shortcuts                                      [ok]
    |   |   |-- prereq.cfg -> prereqs/mysql.cfg                        [N/A]
    |   |   |-- prereqs                                                [ok]
    |   |   |   |-- mysql.cfg                                          [ok]
    |   |   |   `-- pgsql.cfg                                          [ok]
    |   |   `-- scripts                                                [done]
    |   |       |-- api-post-deploy                                    [ok]
    |   |       |-- api-pre-install                                    [ok]
    |   |       `-- oscar_table.sql                                    [ok]
    |   |-- openmpi
    |   |   |-- SRPMS
    |   |   |   |-- README
    |   |   |   |-- build.cfg
    |   |   |   |-- openmpi-1.2.4-1.src.rpm
    |   |   |   `-- openmpi-switcher-modulefile-1.1.1-1.src.rpm
    |   |   |-- config.xml                                                      [done]
    |   |   |-- doc
    |   |   |-- scripts
    |   |   |   `-- client-post_install
    |   |   `-- testing
    |   |       |-- cpi.c
    |   |       |-- cxxhello.cc
    |   |       |-- f77hello.f
    |   |       |-- rm_script.openmpi
    |   |       `-- test_user
    |   |-- opium
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- ssh-oscar-1.1-7.src.rpm
    |   |   |-- config.xml                                                      [done]
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   `-- user.tex
    |   |   `-- scripts
    |   |       `-- api-post-deploy
    |   |-- package.dtd
    |   |-- pfilter
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- pfilter-1.707-3oscar.src.rpm
    |   |   |-- config.xml                                                      [done]
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   `-- scripts
    |   |       `-- api-post-clientdef
    |   |-- pvm
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- pvm-3.4.5+6-2.src.rpm
    |   |   |-- config.xml                                                    [done]
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   |-- scripts
    |   |   `-- testing
    |   |       |-- envvar-pvm_arch.apt
    |   |       |-- envvar-pvm_root.apt
    |   |       |-- envvar.apb
    |   |       |-- install_tests.apb
    |   |       |-- master1.c
    |   |       |-- modulecmd-path-ls.apt
    |   |       |-- pvm-module-list.apt
    |   |       |-- pvm-module-show-pvm_arch.apt
    |   |       |-- pvm-module-show-pvm_root.apt
    |   |       |-- pvm-module-show-pvm_rsh.apt
    |   |       |-- pvm-module-show.apb
    |   |       |-- pvm-module.apb
    |   |       |-- pvmd-path-ls.apt
    |   |       |-- pvmd-path-which.apt
    |   |       |-- rm_script.pvm
    |   |       |-- slave1.c
    |   |       `-- test_user
    |   |-- rapt
    |   |   |-- config.xml                                              [ok]
    |   |   |-- prereq.cfg
    |   |   `-- scripts
    |   |-- sc3
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- sc3-1.2-5.src.rpm
    |   |   |-- config.xml                                          [done]
    |   |   |-- doc
    |   |   |   `-- license.tex
    |   |   `-- scripts
    |   |-- selinux
    |   |   |-- SRPMS
    |   |   |-- config.xml                                          [ok]
    |   |   `-- scripts
    |   |       |-- api-post-image
    |   |       `-- selinx_config_template
    |   |-- sge
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- sge-6.0u9-9oscar.src.rpm
    |   |   |-- config.xml                                          [done]
    |   |   |-- configurator.html
    |   |   |-- doc
    |   |   |   |-- README
    |   |   |   `-- install.tex
    |   |   |-- scripts
    |   |   |   |-- SGE.pm
    |   |   |   |-- api-post-clientdef
    |   |   |   |-- api-post-deploy
    |   |   |   |-- api-post-image
    |   |   |   |-- server-post_install
    |   |   |   `-- templates
    |   |   |       |-- lam.template
    |   |   |       |-- mpich.template
    |   |   |       |-- openmpi.template
    |   |   |       `-- pvm.template
    |   |   `-- testing
    |   |       |-- sge_test
    |   |       `-- test_user
    |   |-- sis
    |   |   |-- SRPMS
    |   |   |   |-- atftp-0.7-8oscar.src.rpm
    |   |   |   |-- bittorrent-4.2.2-1.rf.src.rpm
    |   |   |   |-- bittorrent-4.2.2-2.fc4.src.rpm
    |   |   |   |-- bittorrent-compat-suse-1.0-1.src.rpm
    |   |   |   |-- build.cfg
    |   |   |   |-- flamethrower-0.1.8-1.src.rpm
    |   |   |   |-- perl-AppConfig-1.52-4.src.rpm
    |   |   |   |-- perl-FreezeThaw-0.43-1.rf.src.rpm
    |   |   |   |-- perl-MLDBM-2.01-2.src.rpm
    |   |   |   |-- perl-forks-0.16-1mdk.src.rpm
    |   |   |   |-- perl-reaper-0.03-0.1.20060mdk.src.rpm
    |   |   |   |-- pxelinux-3.11-1mdk.src.rpm
    |   |   |   |-- python-crypto-2.0-1.rf.src.rpm
    |   |   |   |-- python-crypto-2.0.1-1.fc4.src.rpm
    |   |   |   |-- syslinux-2.11-1.src.rpm
    |   |   |   |-- systemconfigurator-2.2.11-1.src.rpm
    |   |   |   |-- systemimager-4.0.2-1.src.rpm
    |   |   |   |-- systeminstaller-oscar-2.3.7-1.src.rpm
    |   |   |   `-- udpcast-20070218-1.src.rpm
    |   |   |-- config.xml                                               [done]
    |   |   |-- configurator.html
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   `-- scripts
    |   |       |-- api-post-clientdef
    |   |       |-- api-post-image
    |   |       |-- server-post-install
    |   |       `-- si_monitor.patch
    |   |-- switcher
    |   |   |-- SRPMS
    |   |   |   |-- README
    |   |   |   |-- build.cfg
    |   |   |   |-- env-switcher-1.0.13-1.src.rpm
    |   |   |   |-- modules-default-manpath-oscar-1.0.1-1.src.rpm
    |   |   |   `-- modules-oscar-3.2.6-1.src.rpm
    |   |   |-- config.xml                                                   [ok]
    |   |   |-- doc
    |   |   |   |-- common.tex
    |   |   |   |-- install.tex
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   `-- scripts
    |   |       |-- api-post-clientdef
    |   |       |-- api-post-configure
    |   |       |-- api-post-deploy
    |   |       |-- package_config.pm
    |   |       |-- pre_configure
    |   |       |-- set_switcher_defaults
    |   |       `-- user_settings.pm
    |   |-- sync-files
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   `-- sync-files-2.4-3.src.rpm
    |   |   |-- config.xml                                               [done]
    |   |   `-- scripts
    |   |       `-- post_rpm_nochroot
    |   |-- torque
    |   |   |-- SRPMS
    |   |   |   |-- build.cfg
    |   |   |   |-- compat-libgfortran-4.0.1-5mdk.src.rpm
    |   |   |   `-- torque-oscar-2.1.10-4.src.rpm
    |   |   |-- config.xml                                                 [done]
    |   |   |-- configurator.html
    |   |   |-- doc
    |   |   |   |-- install.tex
    |   |   |   |-- license.tex
    |   |   |   `-- user.tex
    |   |   |-- scripts
    |   |   |   |-- TORQUE.pm
    |   |   |   |-- api-post-deploy
    |   |   |   |-- client-post_install
    |   |   |   |-- server-post_install
    |   |   |   `-- update_mom_config
    |   |   `-- testing
    |   |       |-- README.pbs_test
    |   |       |-- pbs_script.shell
    |   |       |-- pbs_test
    |   |       |-- test_root
    |   |       `-- test_user
    |   `-- yume
    |       |-- SRPMS
    |       |   |-- build.cfg
    |       |   |-- createrepo-0.4.3-5.1e.src.rpm
    |       |   |-- perl-IO-Tty-1.02-4.oscar.src.rpm
    |       |   |-- python-celementtree-1.0.2-0.1.20060mdk.src.rpm
    |       |   |-- python-elementtree-1.2.6-1mdk.src.rpm
    |       |   |-- python-elementtree-1.2.6-6.1ef.src.rpm
    |       |   |-- python-sqlite-1.0.1-1.rf.src.rpm
    |       |   |-- python-urlgrabber-2.9.6-1mdk.src.rpm
    |       |   |-- python-urlgrabber-2.9.8-2ef.src.rpm
    |       |   |-- sqlite-2.8.16-1.rf.src.rpm
    |       |   |-- yum-2.6.1-1mdk.src.rpm
    |       |   |-- yum-oscar-2.4.3-1.src.rpm
    |       |   `-- yume-2.7-2.src.rpm
    |       |-- config.xml                                               [done]
    |       |-- prereq.cfg
    |       `-- scripts
    |-- scripts
    |   |-- OCA-driver.pl
    |   |-- allow_client_access                                          [ok]
    |   |-- audit-srpm                                                   [ok]
    |   |-- build_all_rpms                                               [ok]
    |   |-- build_opkg_rpms                                              [done]
    |   |-- build_oscar_repo                                             [ok]
    |   |-- build_oscar_rpms                                             [done]
    |   |-- build_rpms                                                   [ok]
    |   |-- c3_conf_manager                                              [ok]
    |   |-- cli
    |   |   |-- build_oscar_image_cli
    |   |   |-- configurator.xsd
    |   |   |-- define_oscar_clients_cli
    |   |   |-- main_cli
    |   |   |-- modules.used                                            [ok]
    |   |   |-- selector_cli
    |   |   `-- simple_complete.pl                                      [ok]
    |   |-- client_status                                               [ok]
    |   |-- create_and_populate_basic_node_info                         [ok]
    |   |-- create_oscar_database                                       [ok]
    |   |-- deb_depends                                                 [ok]
    |   |-- debs_require                                                [ok]
    |   |-- distro-query                                                [N/A]
    |   |-- get-oscar-version.sh                                        [done]
    |   |-- get_arch                                                    [ok]
    |   |-- get_num_proc                                                [ok]
    |   |-- install_prereq                                              [done]
    |   |-- install_server                                              [done]
    |   |-- integrate_image                                             [ok]
    |   |-- mac_collector                                               [ok]
    |   |-- macinfo2sis                                                 [ok]
    |   |-- make_database_password                                      [ok]
    |   |-- msm_driver                                                  [N/A]
    |   |-- oda                                                         [done]
    |   |-- opd                                                         [done]
    |   |-- opd2                                                        [ok]
    |   |-- oscar-cluster                                               [N/A]
    |   |-- oscar-config                                                [N/A]
    |   |-- oscar_image_cleanup                                         [ok]
    |   |-- oscar_wizard                                                [ok]
    |   |-- ping_clients                                                [ok]
    |   |-- populate_default_package_set                                [ok]
    |   |-- populate_oda_packages_table                                 [done]
    |   |-- post_clients                                                [ok]
    |   |-- post_install                                                [ok]
    |   |-- post_rpm_install                                            [ok]
    |   |-- prep_oscar_repos                                            [ok]
    |   |-- prepare_oda                                                 [done]
    |   |-- prepare_repos                                               [ok]
    |   |-- psm_driver                                                  [N/A]
    |   |-- repo-update                                                 [ok]
    |   |-- rpm_depends                                                 [ok]
    |   |-- rpms_require                                                [ok]
    |   |-- sanity_check                                                [ok]
    |   |-- set_global_oscar_values                                     [done]
    |   |-- set_node_nics                                               [ok]
    |   |-- set_oscar_interface                                         [ok]
    |   |-- setup_pxe                                                   [done]
    |   |-- ssh_install                                                 [ok]
    |   |-- start_over                                                  [done]
    |   |-- svn_ignore                                                  [ok]
    |   |-- system-sanity                                               [ok]
    |   |-- system-sanity.d                                             [done]
    |   |   |-- debrepo-check.pl                                        [ok]
    |   |   |-- display-check.pl                                        [ok]
    |   |   |-- network-check.pl                                        [done]
    |   |   |-- selinux-check.pl                                        [ok]
    |   |   |-- ssh-check.pl                                            [ok]
    |   |   |-- su-check.pl                                             [ok]
    |   |   |-- tftpboot-check.pl                                       [done]
    |   |   `-- yum-check.pl                                            [ok]
    |   |-- update_live_macs                                            [ok]
    |   `-- wizard_prep                                                 [done]
    |-- share
    |   |-- machine_sets
    |   |-- package_sets
    |   |   |-- Default
    |   |   |   |-- debian-4-i386.xml
    |   |   |   |-- debian-4-x86_64.xml
    |   |   |   |-- fc-5-i386.xml
    |   |   |   |-- fc-6-i386.xml
    |   |   |   |-- fc-6-x86_64.xml
    |   |   |   |-- fc-7-i386.xml
    |   |   |   |-- fc-7-x86_64.xml
    |   |   |   |-- fc-8-i386.xml
    |   |   |   |-- fc-8-x86_64.xml
    |   |   |   |-- fc-9-x86_64.xml
    |   |   |   |-- rhel-4-i386.xml
    |   |   |   |-- rhel-4-x86_64.xml
    |   |   |   |-- rhel-5-i386.xml
    |   |   |   |-- rhel-5-x86_64.xml
    |   |   |   |-- suse-10-x86_64.xml
    |   |   |   |-- suse-10.2-x86_64.xml
    |   |   |   |-- suse-10.3-x86_64.xml
    |   |   |   `-- ydl-5-ppc64.xml
    |   |   `-- testing -> ../../testing/apitests/psm/files/
    |   |-- prereqs
    |   |   |-- base
    |   |   |   `-- prereq.cfg
    |   |   |-- packman
    |   |   |   |-- SRPMS
    |   |   |   |   |-- build.cfg
    |   |   |   |   `-- packman-depman-2.9.0-1.src.rpm
    |   |   |   `-- prereq.cfg
    |   |   |-- perl-HTML-Tree
    |   |   |   |-- SRPMS
    |   |   |   |   |-- build.cfg
    |   |   |   |   `-- perl-HTML-Tree-3.23-1.rf.src.rpm
    |   |   |   `-- prereq.cfg
    |   |   |-- perl-Qt
    |   |   |   |-- SRPMS
    |   |   |   |   |-- build.cfg
    |   |   |   |   |-- kdebindings3-3.4.2-8.src.rpm
    |   |   |   |   |-- perl-Qt-3.008-132.src.rpm
    |   |   |   |   |-- perl-Qt-3.009b2-6.src.rpm
    |   |   |   |   |-- perl-Qt-compat-suse-1.0-1.src.rpm
    |   |   |   |   |-- perl-Qt-mdk10-3.008-4mdk.src.rpm
    |   |   |   |   `-- smokeqt-1.2.1-3mdk.src.rpm
    |   |   |   `-- prereq.cfg
    |   |   |-- perl-Tk
    |   |   |   |-- SRPMS
    |   |   |   |   |-- build.cfg
    |   |   |   |   |-- perl-Tie-Watch-1.1-1mdk.src.rpm
    |   |   |   |   |-- perl-Tk-804.026-1.oscar.src.rpm
    |   |   |   |   `-- perl-Tk-804.027-2mdk.src.rpm
    |   |   |   `-- prereq.cfg
    |   |   |-- perl-XML-Parser
    |   |   |   `-- prereq.cfg
    |   |   |-- perl-XML-Simple
    |   |   |   |-- SRPMS
    |   |   |   |   |-- build.cfg
    |   |   |   |   `-- perl-XML-Simple-2.14-2.rf.src.rpm
    |   |   |   `-- prereq.cfg
    |   |   `-- prereqs.order
    |   `-- schemas
    |       |-- machineset.xsd
    |       `-- pkgset.xsd
    |-- src
    |   |-- Installer
    |   |   |-- Doxyfile
    |   |   |-- Installer.pl
    |   |   |-- Installer.xml
    |   |   |-- InstallerAPI.txt
    |   |   |-- InstallerErrorDialog.ui
    |   |   |-- InstallerErrorDialog.ui.h
    |   |   |-- InstallerMainWindow.pm
    |   |   |-- InstallerParseXML.pm
    |   |   |-- InstallerUtils.pm
    |   |   |-- InstallerWorkspace.pm
    |   |   |-- Makefile
    |   |   `-- images
    |   |       |-- backarrow.png
    |   |       |-- ball1.png
    |   |       |-- ball2.png
    |   |       |-- ball3.png
    |   |       |-- ball4.png
    |   |       |-- ball5.png
    |   |       |-- close.png
    |   |       |-- config.png
    |   |       |-- download.png
    |   |       |-- editcopy.png
    |   |       |-- editcut.png
    |   |       |-- editpaste.png
    |   |       |-- filenew.png
    |   |       |-- fileopen.png
    |   |       |-- filesave.png
    |   |       |-- getinfo.png
    |   |       |-- nextarrow.png
    |   |       |-- oscarbg.png
    |   |       |-- print.png
    |   |       |-- redo.png
    |   |       |-- searchfind.png
    |   |       `-- undo.png
    |   |-- Makefile
    |   |-- NodeGroupLister
    |   |   |-- GUI.xml
    |   |   |-- Makefile
    |   |   |-- NodeGroupLister.pro
    |   |   |-- NodeGroupLister.ui
    |   |   `-- NodeGroupLister.ui.h
    |   |-- NodeMgmt
    |   |   |-- GUI.xml
    |   |   |-- Makefile
    |   |   |-- NodeMgmt.pro
    |   |   |-- NodeMgmtDialog.ui
    |   |   |-- NodeMgmtDialog.ui.h
    |   |   |-- NodeMgmtTable.pm
    |   |   |-- NodeSettingsDialog.ui
    |   |   `-- NodeSettingsDialog.ui.h
    |   |-- ORM                                                       [N/A]
    |   |   |-- ChangeLog                                             [N/A]
    |   |   |-- Makefile                                              [N/A]
    |   |   |-- src                                                   [N/A]
    |   |   |   |-- AddRepoWidget.ui                                  [N/A]
    |   |   |   |-- CommandExecutionThread.cpp                        [N/A]
    |   |   |   |-- CommandExecutionThread.h                          [N/A]
    |   |   |   |-- ORM.ui                                            [N/A]
    |   |   |   |-- ORM_AddRepoGUI.cpp                                [N/A]
    |   |   |   |-- ORM_AddRepoGUI.h                                  [N/A]
    |   |   |   |-- ORM_MainGUI.cpp                                   [N/A]
    |   |   |   |-- ORM_MainGUI.h                                     [N/A]
    |   |   |   |-- ORM_WaitDialog.cpp                                [N/A]
    |   |   |   |-- ORM_WaitDialog.h                                  [N/A]
    |   |   |   |-- WaitDialog.ui                                     [N/A]
    |   |   |   |-- doxygen_config                                    [N/A]
    |   |   |   |-- main.cpp                                          [N/A]
    |   |   |   |-- pstream.h                                         [N/A]
    |   |   |   `-- tags                                              [N/A]
    |   |   `-- xorm.pro                                              [N/A]
    |   |-- Opder
    |   |   |-- GUI.xml
    |   |   |-- Makefile
    |   |   |-- Opder.pro
    |   |   |-- Opder.ui
    |   |   |-- Opder.ui.h
    |   |   |-- OpderAddRepository.ui
    |   |   |-- OpderAddRepository.ui.h
    |   |   |-- OpderDownloadInfo.ui
    |   |   |-- OpderDownloadInfo.ui.h
    |   |   |-- OpderDownloadPackage.ui
    |   |   |-- OpderDownloadPackage.ui.h
    |   |   |-- OpderLWP.pm
    |   |   `-- OpderTable.pm
    |   |-- OscarGui2
    |   |   |-- OscarGUI.ui
    |   |   `-- README
    |   |-- OscarSets
    |   |   |-- README
    |   |   |-- machinesetsexample.xml
    |   |   `-- pkgsetexample-fedora-6-i386.xml
    |   |-- Selector
    |   |   |-- GUI.xml
    |   |   |-- Makefile
    |   |   |-- Selector.pro
    |   |   |-- Selector.ui
    |   |   |-- Selector.ui.h
    |   |   |-- SelectorTable.pm
    |   |   `-- SelectorUtils.pm
    |   |-- opm
    |   |   |-- opm.pl
    |   |   `-- osmToOpm.pm
    |   `-- xoscar                                                       [N/A]
    |       |-- TODO                                                     [N/A]
    |       |-- configure                                                [N/A]
    |       |-- doc                                                      [N/A]
    |       |-- icons                                                    [N/A]
    |       |   |-- configure.png                                        [N/A]
    |       |   |-- kcontrol.png                                         [N/A]
    |       |   |-- list-add.png                                         [N/A]
    |       |   |-- list-remove.png                                      [N/A]
    |       |   `-- oscar.gif                                            [N/A]
    |       |-- src                                                      [N/A]
    |       |   |-- AboutAuthorsDialog.ui                                [N/A]
    |       |   |-- AboutOSCARDialog.ui                                  [N/A]
    |       |   |-- AddDistroWidget.ui                                   [N/A]
    |       |   |-- AddRepoWidget.ui                                     [N/A]
    |       |   |-- CommandExecutionThread.cpp                           [N/A]
    |       |   |-- CommandExecutionThread.h                             [N/A]                         
    |       |   |-- FileBrowser.ui                                       [N/A]
    |       |   |-- ORM_AddDistroGUI.cpp                                 [N/A]
    |       |   |-- ORM_AddDistroGUI.h                                   [N/A]
    |       |   |-- ORM_AddRepoGUI.cpp                                   [N/A]
    |       |   |-- ORM_AddRepoGUI.h                                     [N/A]
    |       |   |-- ORM_WaitDialog.cpp                                   [N/A]
    |       |   |-- ORM_WaitDialog.h                                     [N/A]
    |       |   |-- WaitDialog.ui                                        [N/A]
    |       |   |-- XOSCAR_AboutAuthorsDialog.cpp                        [N/A]
    |       |   |-- XOSCAR_AboutAuthorsDialog.h                          [N/A]
    |       |   |-- XOSCAR_AboutOscarDialog.cpp                          [N/A]
    |       |   |-- XOSCAR_AboutOscarDialog.h                            [N/A]
    |       |   |-- XOSCAR_FileBrowser.cpp                               [N/A]
    |       |   |-- XOSCAR_FileBrowser.h                                 [N/A]
    |       |   |-- XOSCAR_MainWindow.cpp                                [N/A]
    |       |   |-- XOSCAR_MainWindow.h                                  [N/A]
    |       |   |-- doxygen_config                                       [N/A]
    |       |   |-- main.cpp                                             [N/A]
    |       |   |-- pstream.h                                            [N/A]
    |       |   `-- xoscar_mainwindow.ui                                 [N/A]
    |       |-- xoscar.pro                                               [N/A]
    |       `-- xoscar_resource.qrc                                      [N/A]
    |-- testing                                                          
    |   |-- README.testing
    |   |-- apitests
    |   |   |-- oscartest.apb
    |   |   `-- psm
    |   |       |-- files
    |   |       |   |-- test-all.xml
    |   |       |   |-- test-eq-bad.xml
    |   |       |   |-- test-eq-good.xml
    |   |       |   |-- test-gt-bad.xml
    |   |       |   |-- test-gt-good.xml
    |   |       |   |-- test-gte-bad.xml
    |   |       |   |-- test-gte-good.xml
    |   |       |   |-- test-lt-bad.xml
    |   |       |   |-- test-lt-good.xml
    |   |       |   |-- test-lte-bad.xml
    |   |       |   |-- test-lte-good.xml
    |   |       |   |-- test-none.xml
    |   |       |   `-- test2.xml
    |   |       |-- psm_1.apt
    |   |       |-- psm_10.apt
    |   |       |-- psm_2.apt
    |   |       |-- psm_3.apt
    |   |       |-- psm_4.apt
    |   |       |-- psm_5.apt
    |   |       |-- psm_6.apt
    |   |       |-- psm_7.apt
    |   |       |-- psm_8.apt
    |   |       |-- psm_9.apt
    |   |       `-- psmtest.apb
    |   |-- oscar-testing.txt
    |   |-- run_unit_test
    |   |-- ssh_user_tests
    |   |-- test_cluster
    |   |-- test_oca.pl
    |   |-- test_system-sanity.pl
    |   |-- testprint
    |   `-- unit_testing                                                     [N/A]
    |       |-- samples                                                      [N/A]
    |       |   `-- config.xml                                               [N/A]
    |       `-- test_configxml                                               [N/A]
    `-- tmp                                                                  [N/A]
