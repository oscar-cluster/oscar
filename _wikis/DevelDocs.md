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

[Back the Documentations Main Page](Document)

## Developer Documentation

### Table of Contents

 1. Development Process
    * [Coding Style](CodingStyle)
    * Release Management
      * [Code Freeze and Release](CodeFreeze) 
      * [Release Processes](ReleaseProcess) 
    * SVN
      * [Checkout Instructions](SVNinstructions) 
      * [Merges](SvnMerges) 
      * [Integration with Trac](SvnTrac) 
      * [Rollback](SvnRollback) 

 1. Preparations
   * [Autoinstalling the headnode](AutoInstallHead)
   * [Build servers at Indiana University](IndianaServers)
   * [OSCAR debug parameters](DebugOSCAR)

 1. OSCAR infrastructure
   * OSCAR Overview
         * [Future & Ongoing Work](roadmap) 
         * [Architecture](architecture) 
   * OSCAR Packages (opkg)
         * [The OPKG API](opkgAPI) 
         * [Opkg](Opkg)
         * [Packaging for OSCAR](Packaging) 
         * [PackageInUn](PackageInUn) (deprecated)
         * [OSCAR Package Manger](OPM)
   * [OCA: OSCAR Component Architecture](DevOCA)
         * [OS_Detect](DevOSdetect) 
         * [OS_Settings](DevOSsettings) 
         * [RM_Detect](DevRMdetect) 
         * [Sanity_Check](DevSanityCheck) 
   * [OSCAR Configuration Files](ConfigFile)
   * [ODA: OSCAR Database](DevODA)
         * [Bootstrap](DevODA_Bootstrap) 
         * [Architecture](DevODA_architecture) 
         * [Code Source, Installation and Packaging](DevODA_code) 
         * [Maintenance of ODA](DevODA_maintenance) 
   * OPD: OSCAR Package Downloader
         * [OPD2 Architecture](DevOPD2) 
   * [generic-setup](GenericSetup)
   * [prereqs](DevPrereqs)
   * [system-sanity](SystemSanity)
   * [packman](DevPackman)
   * [OSCAR::PackagePath](PackagePath)
   * [KernelPicker](KernelPicker)
   * [Switcher](switcher)
   * [SystemInstaller](SystemInstaller)
   * [SystemConfigurator](SystemConfigurator)
   * [Command Line Interface](CLI)
         * [Selector](Selector)
         * [Configurator](Configurator)
         * [Install Server RPMs](InstallServer) 
         * [Build Client Image](Build) 
         * [Define OSCAR Clients](Define) 
         * [Setup Networking](SetupNetwork) 
         * [Complete and Test Cluster Installation](CompleteTest) 
   * [Oscar Set Manager](OSM)
         * [Package Set Manager](SetManager) 
              * [OPKG Versioning](OPKGVersioning) 
              * [Initial Implementation of Package Sets](OPKGSetTemp) 
         * [Machine Set Manager](MSM) 
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
   * [OscarReleaseTesting](OscarReleaseTesting)
   * [Testing of OSCAR trunk](trunkTesting)
   * [Testing the OSCAR version available via our repositories](repoTesting)
 1. Ongoing work ...
    * [Roadmap](roadmap) 
    * [WebORM](weborm) 
    * [OSCARonDebian](OSCARonDebian) 
    * [OSCAR Package Compiler (opkgc)](opkg_opkgc) 
