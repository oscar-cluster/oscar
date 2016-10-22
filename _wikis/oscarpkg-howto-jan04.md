---
layout: wiki
title: oscarpkg-howto-jan04
meta: 
permalink: "/wiki/oscarpkg-howto-jan04"
category: wiki
---
<!-- Name: oscarpkg-howto-jan04 -->
<!-- Version: 1 -->
<!-- Author: amitvyas -->

``` 
  This page is under development information present on this page might be incorrect.  
This page is text copy of http://oscar.openclustergroup.org/public/docs/devel/oscarpkg-howto_22jan04.pdf  <oscar-root>/docs/oscarpkg-howto/
```

HOWTO: Create an OSCAR Package 

Core OSCAR Team 

January 22, 2004 

Draft $Id: oscarpkg-howto.tex,v 1.15 2004/01/22 03:42:04 naughtont Exp $ 

Contents 

1 Introduction 3 

1.1 Super Short Summary ........................................... 3


2 Package Layout 3 

2.1 config.xml .............................................. 4


2.2 RPMS&SRPMS ............................................. 4


2.3 scripts................................................... 4


2.3.1 PackageSetup .......................................... 5


2.3.2 Configurator ........................................... 6


2.3.3 FixupswithoutRPMmodification ................................ 6


2.3.4 SetupafterClientsDefined .................................... 6


2.3.5 Completingclusterconfigurations ................................ 7


2.3.6 PackageUninstall ......................................... 7


2.4 testing................................................... 7


2.5 doc..................................................... 7


3 Example Package 8 

3.1 A basic config.xml .......................................... 8


3.2 UsingtheConfigurator .......................................... 8


3.2.1 postconfigure .......................................... 9


3.3 postclients ................................................ 10


3.4 postinstall ................................................ 11


4 OSCAR Package Downloader (OPD) 11 

5 OSCAR Database (ODA) 12 

6 OSCAR Configurator 12 

A Rules of Thumb 18 

A.1 InstallLocation .............................................. 18


A.2 OSCARSpecificRPMS ......................................... 18


A.3 init.dscripts.............................................. 18


A.4 GeneratingConfigurationFiles ...................................... 18


B Env-Switcher 18 

B.1 ExampleSwitcherModulefile ...................................... 19


C Supported XML Tags 19 

1 


List of Tables 
1 Environment Variables . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 4 
2 Package API Scripts . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 5 
3 Outline of operations performed . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 5 
4 OSCAR Package XML tags . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 20 

2 
