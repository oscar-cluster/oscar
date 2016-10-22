---
layout: blog
title: Monthly Chairman Bulletin - December 2008
meta: Monthly Chairman Bulletin - December 2008
category: trac
folder: trac
---
<!-- Name: bulletin_dec08 -->
<!-- Version: 2 -->
<!-- Last-Modified: 2008/12/22 15:07:31 -->
<!-- Author: valleegr -->

*OSCAR 5.2 becomes OSCAR 6.0 and a beta version is now available! *

Fist of all, let's explain why we decided to call the next release 6.0 instead of 5.2. It is actually very simple: the way OSCAR is initialized changed and the different commands users are supposed to use also changed. Therefore, there is no good compatibility between OSCAR-5.1 and the new release. Because of this lack of compabilities, we decided to version this release 6.0 instead of 5.2.

Now, what about the beta version? Again it is pretty simple: *we were able to deploy a production CentOS-5 x86_64 cluster using this version*, we do not expect to find any major bug with that version so we plan to release it as soon as possible. The deployment has been made using OSCAR core of course, plus Ganglia (other OPKGs have not been "ported" yet).
This means that the OSCAR-6.0 version is not necessarily suitable for production. OSCAR-6.0 is actually very similar to KDE-4.0: this version is not necessarily "designed" for the users who need all the capabilities traditionally shipped with OSCAR, but this is a good new framework to include and develop new capabilities and move forward.

Finally, just few words about the *Debian support*: we found a critical bug in OPKGC on Debian therefore we will not be able to officially support Debian in OSCAR-6.0. However, users should be able to deploy a cluster based on OSCAR core.

To test this version (it officially supports only CentOS-5 both x86 and x86_64), please use our online repositories, more information is available here: http://svn.oscar.openclustergroup.org/trac/oscar/wiki/repoTesting

*If no bugs are reported within the next two weeks, we will release OSCAR-6.0 on January, 5th.*