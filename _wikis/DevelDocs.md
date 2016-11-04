---
layout: wiki
title: DevelDocs
meta: 
permalink: "wiki/DevelDocs"
category: wiki
---
<!-- Name: DevelDocs -->
<!-- Version: 100 -->
<!-- Author: valleegr -->

[[TOC(CodingStyle, CodeFreeze, ReleaseProcess, SvnMerges, AutoInstallHead, IndianaServers, DebugOSCAR, DevODA, DevOCA, GenericSetup, DevPrereqs, SystemSanity, DevPackman, KernelPicker, SystemInstaller, Opkg, CLI, PackageMaintainers, Packaging, DistroSupport, BuildOverview, Distribution, depth=1)]]

# Developer Documentation

### Table of Contents

 1. Development Process
    * [CodingStyle Coding Style]
    * Release Management
      * [CodeFreeze Code Freeze and Release]
      * [ReleaseProcess Release Processes]
    * SVN
      * [SVNinstructions Checkout Instructions]
      * [SvnMerges Merges]
      * [SvnTrac Integration with Trac]
      * [SvnRollback Rollback]
 1. Preparations
   * [Autoinstalling the headnode](AutoInstallHead)
   * [Build servers at Indiana University](IndianaServers)
   * [OSCAR debug parameters](DebugOSCAR)
 1. OSCAR infrastructure
   * OSCAR Overview
     * [roadmap Future & Ongoing Work]
     * [architecture Architecture]
   * OSCAR Packages (opkg)
     * [opkgAPI The OPKG API]
     * [Opkg]
     * [Packaging Packaging for OSCAR]
     * [PackageInUn PackageInUn] (deprecated)
     * [OPM]: OSCAR Package Manger
   * [OCA](DevOCA): OSCAR Component Architecture
     * [DevOSdetect OS_Detect]
     * [DevOSsettings OS_Settings]
     * [DevRMdetect RM_Detect]
     * [DevSanityCheck Sanity_Check]
   * [OSCAR Configuration Files](ConfigFile)
   * [ODA](DevODA): OSCAR Database
     * [DevODA_Bootstrap Bootstrap]
     * [DevODA_architecture Architecture]
     * [DevODA_code Code Source, Installation and Packaging]
     * [DevODA_maintenance Maintenance of ODA]
   * OPD: OSCAR Package Downloader
     * [DevOPD2 OPD2 Architecture]
   * [generic-setup](GenericSetup)
   * [prereqs](DevPrereqs)
   * [system-sanity](SystemSanity)
   * [packman](DevPackman)
   * [OSCAR::PackagePath](PackagePath)
   * [KernelPicker](KernelPicker)
   * [Switcher](switcher)
   * [SystemInstaller]
   * [SystemConfigurator]
   * [Command Line Interface](CLI)
     * [Selector]
     * [Configurator]
     * [InstallServer Install Server RPMs]
     * [Build Build Client Image]
     * [Define Define OSCAR Clients]
     * [SetupNetwork Setup Networking]
     * [CompleteTest Complete and Test Cluster Installation]
   * [Oscar Set Manager](OSM)
     * [SetManager Package Set Manager]
       * [OPKGVersioning OPKG Versioning]
       * [OPKGSetTemp Initial Implementation of Package Sets]
     * [MSM Machine Set Manager]
   * [RAPT](RAPT)
   * [Monitoring Framework](monitoring_framework)
 1. [Backing up OSCAR](BackupOSCAR) (-> this should move to the user/admin docs!)
 1. OSCAR Distribution Support
   * [Distribution support for new OSCAR releases](DistroSupport)
   * [Porting OSCAR to a new distribution](DistroPort)
   * [OSCAR binary packages repositories](OSCARRepositories)
 1. Build system
   * [Overview](BuildOverview)
   * [New OSCAR distribution format](Distribution)
 1. Build OSCAR packages
   * [Building all packages required by OSCAR](Building_OSCAR_Packages)
   * [Building OSCAR meta packages (opkgs)](Building_Opkgs)
 1. Testing
   * [Manual Testing of PVM](PvmTesting)
   * [OscarReleaseTesting]
   * [Testing of OSCAR trunk](trunkTesting)
   * [Testing the OSCAR version available via our repositories](repoTesting)
 1. Ongoing work ...
    * [roadmap Roadmap]
    * [weborm WebORM]
    * [OSCARonDebian OSCARonDebian]
    * [opkg_opkgc OSCAR Package Compiler (opkgc)]
