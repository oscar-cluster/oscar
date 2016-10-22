---
layout: wiki
title: DevelDocs
meta: 
permalink: "/wiki/DevelDocs"
category: wiki
---
<!-- Name: DevelDocs -->
<!-- Version: 100 -->
<!-- Author: valleegr -->

[[TOC(CodingStyle, CodeFreeze, ReleaseProcess, SvnMerges, AutoInstallHead, IndianaServers, DebugOSCAR, DevODA, DevOCA, GenericSetup, DevPrereqs, SystemSanity, DevPackman, KernelPicker, SystemInstaller, Opkg, CLI, PackageMaintainers, Packaging, DistroSupport, BuildOverview, Distribution, depth=1)]]

# Developer Documentation

### Table of Contents

 1. Development Process
    * [wiki/CodingStyle Coding Style]
    * Release Management
      * [wiki/CodeFreeze Code Freeze and Release]
      * [wiki/ReleaseProcess Release Processes]
    * SVN
      * [wiki/SVNinstructions Checkout Instructions]
      * [wiki/SvnMerges Merges]
      * [wiki/SvnTrac Integration with Trac]
      * [wiki/SvnRollback Rollback]
 1. Preparations
   * [Autoinstalling the headnode](/wiki/AutoInstallHead/)
   * [Build servers at Indiana University](/wiki/IndianaServers/)
   * [OSCAR debug parameters](/wiki/DebugOSCAR/)
 1. OSCAR infrastructure
   * OSCAR Overview
     * [wiki/roadmap Future & Ongoing Work]
     * [wiki/architecture Architecture]
   * OSCAR Packages (opkg)
     * [wiki/opkgAPI The OPKG API]
     * [wiki/Opkg]
     * [wiki/Packaging Packaging for OSCAR]
     * [wiki/PackageInUn PackageInUn] (deprecated)
     * [wiki/OPM]: OSCAR Package Manger
   * [OCA](/wiki/DevOCA/): OSCAR Component Architecture
     * [wiki/DevOSdetect OS_Detect]
     * [wiki/DevOSsettings OS_Settings]
     * [wiki/DevRMdetect RM_Detect]
     * [wiki/DevSanityCheck Sanity_Check]
   * [OSCAR Configuration Files](/wiki/ConfigFile/)
   * [ODA](/wiki/DevODA/): OSCAR Database
     * [wiki/DevODA_Bootstrap Bootstrap]
     * [wiki/DevODA_architecture Architecture]
     * [wiki/DevODA_code Code Source, Installation and Packaging]
     * [wiki/DevODA_maintenance Maintenance of ODA]
   * OPD: OSCAR Package Downloader
     * [wiki/DevOPD2 OPD2 Architecture]
   * [generic-setup](/wiki/GenericSetup/)
   * [prereqs](/wiki/DevPrereqs/)
   * [system-sanity](/wiki/SystemSanity/)
   * [packman](/wiki/DevPackman/)
   * [OSCAR::PackagePath](/wiki/PackagePath/)
   * [KernelPicker](/wiki/KernelPicker/)
   * [Switcher](/wiki/switcher/)
   * [wiki/SystemInstaller]
   * [wiki/SystemConfigurator]
   * [Command Line Interface](/wiki/CLI/)
     * [wiki/Selector]
     * [wiki/Configurator]
     * [wiki/InstallServer Install Server RPMs]
     * [wiki/Build Build Client Image]
     * [wiki/Define Define OSCAR Clients]
     * [wiki/SetupNetwork Setup Networking]
     * [wiki/CompleteTest Complete and Test Cluster Installation]
   * [Oscar Set Manager](/wiki/OSM/)
     * [wiki/SetManager Package Set Manager]
       * [wiki/OPKGVersioning OPKG Versioning]
       * [wiki/OPKGSetTemp Initial Implementation of Package Sets]
     * [wiki/MSM Machine Set Manager]
   * [RAPT](/wiki/RAPT/)
   * [Monitoring Framework](/wiki/monitoring_framework/)
 1. [Backing up OSCAR](/wiki/BackupOSCAR/) (-> this should move to the user/admin docs!)
 1. OSCAR Distribution Support
   * [Distribution support for new OSCAR releases](/wiki/DistroSupport/)
   * [Porting OSCAR to a new distribution](/wiki/DistroPort/)
   * [OSCAR binary packages repositories](/wiki/OSCARRepositories/)
 1. Build system
   * [Overview](/wiki/BuildOverview/)
   * [New OSCAR distribution format](/wiki/Distribution/)
 1. Build OSCAR packages
   * [Building all packages required by OSCAR](/wiki/Building_OSCAR_Packages/)
   * [Building OSCAR meta packages (opkgs)](/wiki/Building_Opkgs/)
 1. Testing
   * [Manual Testing of PVM](/wiki/PvmTesting/)
   * [wiki/OscarReleaseTesting]
   * [Testing of OSCAR trunk](/wiki/trunkTesting/)
   * [Testing the OSCAR version available via our repositories](/wiki/repoTesting/)
 1. Ongoing work ...
    * [wiki/roadmap Roadmap]
    * [wiki/weborm WebORM]
    * [wiki/OSCARonDebian OSCARonDebian]
    * [wiki/opkg_opkgc OSCAR Package Compiler (opkgc)]
