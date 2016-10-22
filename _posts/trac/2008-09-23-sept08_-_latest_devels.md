---
layout: blog
title: Monthly Chairman Bulletin - September 2008
meta: Monthly Chairman Bulletin - September 2008
category: trac
folder: trac
---
<!-- Name: sept08_-_latest_devels -->
<!-- Version: 1 -->
<!-- Last-Modified: 2008/09/23 16:49:19 -->
<!-- Author: valleegr -->

This month i would like to point at the latest developments on the OSCAR core:
    * OSCAR Repository Manager, a.k.a. ORM, has appeared. ORM is a simple
      abstraction on top of PackMan that allows one to easily deal with a given
      Linux distribution: when creating a new ORM object, one can specify the
      Linux distribution the object is associated with, and then ORM knows
      which OSCAR repositories must be used, how to bootstrap an image, and how 
      to manage binary packages.
      This abstraction is usefull to simplify some OSCAR related code. For
      instance, SystemInstaller can now be modified to rely on ORM for image
      creation, avoiding the current implementation based on several modules,
      specific to SystemInstaller, and duplicating capabilities already 
      provided by others OSCAR components.
      For more details about ORM, please refer to ''perldoc
      OSCAR::RepositoryManager'' after the installation of ORM on your system.
    * Audit of the Selector code: thanks to the effort of OSCAR developers, we
      have now a specification of Selector's capabilities. This audit allowed 
      us to identify implementation limitations and to address those  
      limitations.
      Thanks to these modifications, Selector is now much faster and is 
      actually based on a clear and well-specified interface with ODA, the 
      OSCAR database (Selector get/set data from/into ODA).
      For more details, refer to the Selector documentation, which is available
      with the Selector code, under to ''doc'' directory.
    * Separation of the code of the different OSCAR core components: the source
      code of ODA, Selector, and ORM are now separated from the source code of
      OSCAR trunk. This source code for those components is now in ''pkgsrc''
      (http://svn.oscar.openclustergroup.org/trac/oscar/browser/pkgsrc). This
      organization of the source code allows us to have a fine grain management
      of the different developments: each components can have its own release
      cycle and dependencies between components can easily be expressed via
      binary packages dependencies (especially since, nowadays, OSCAR is entirely
      shipped via binary packages).