---
layout: wiki
title: monitoring_framework
meta: 
permalink: "wiki/monitoring_framework"
category: wiki
---
<!-- Name: monitoring_framework -->
<!-- Version: 3 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure 

## OSCAR Monitoring Framework

The OSCAR Monitoring Framework aims to provide a "link" between a low-level monitoring mechanism (such as IPMI) and all the different OSCAR components. Therefore, this framework aims at being modular and extensible.

For a full documentation of the monitoring framework, please refer to the documentation provided with the OSCAR code (into the doc/monitoring-framework directory - [http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/doc/monitoring-framework](http://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/doc/monitoring-framework)). Two format are available for this documentation PDF and HTML:

 - PDF format: to generate the PDF documentation, from the OSCAR source code, go into the directory 'doc/monitoring-framework' and type 'make pdf',
 - HTML format: to generate the PDF documentation, from the OSCAR source code, go into the directory 'doc/monitoring-framework' and type 'make html'.

A Google Summer of Code 2008 project has been accepted which is based on this framework (and therefore contribute to its implementation): [http://code.google.com/soc/2008/oscar/appinfo.html?csaid=5E434003EE025889](http://code.google.com/soc/2008/oscar/appinfo.html?csaid=5E434003EE025889)
