---
layout: wiki
title: ood_news_archive
meta: 
permalink: "/wiki/ood_news_archive"
category: wiki
---
<!-- Name: ood_news_archive -->
<!-- Version: 3 -->
<!-- Author: valleegr -->

[wiki/OSCARonDebian] > [News Archive](/wiki/ood_news_archive/)

The news are currently handled by Geoffroy Vallee (Oak Ridge National Laboratory). 

  12-22-2008:  Opium has been ported to Debian. All OSCAR core components are now working on Debian.

  02-02-2008:  I am woring again on OSCAR during my free time. My latest contributions include:stabilize the Debian support improving few OSCAR core mechanisms such as the prereqs management mechanism; the database schema changes again, no documentation is available so i implemented a flat file ODA db which allows me to speed up in my developments (no need to wait for other developers who go in every direction without synchronization); inclusion of a configuration file (it is about time!); the development of a new Qt-4 GUI; the creation of man pages for the OSCAR sripts (it is about time too!!!); and some other minor stuff. In other terms, i think i go in the good direction and i can now be much more efficient. I hope to include a virtualization support soon. 

  10-17-2007:  Even if i did not post news since a while, i have been work a lot on OSCAR lately, sometime directly on OSCARonDebian, sometime on OSCAR features that are not directly related to Debian. The few interesting point have been working on are: integration of the creation of base Debian packages directly into trunk (you can use 'make basedebs' now); cluster partitioning, using NEST/OPM; support of OPKGC. Note that i steped back from the project few weeks ago, other developers being active again in order to release a new version of OSCAR and doing stuff i do not understand or agree with. 

  10-17-2007:  Andrea Righi, one of the most active developer of SIS, included files for the creation of Debian packages directly into trunk. This version will be used for the creation of non-official Debian packages, we will continue to use systemimager-debian for the creation of official packages (the constraints are not exactly the same). Note that when i say "we" it does not assume i am an official maintainer of the official Debian packages. :-) 

  08-02-2007:  I updated the Debian packages for SystemImager. The new version fixes issues when installing the packages on a fresh installation (i.e. systemimager never has been installed before). I still have some weird behavior in some very particular cases. 

  06-18-2007:  I just checked-in a Debian package for the sync_file OPKG. Note that there is a namespace issue since the character "_" is used in the name. The Debian package is therefore named "sync-files" instead of "sync_files". A bug report as been created (bug #315). 

  06-13-2007:  I just checked-in packages for Etch x86 and APItest support. These packages still have to be tested in more details. Note that with these packages, we should be able to easily have a full support of Etch x86 and x86_64. 

  06-10-2007:  Last night i have been working on OSCAR on Debian and i have been able to create RPM based images on Debian! For that i really want to thank OSCAR developers that have been working on PackMan, SystemImager, Yume and Rapt; therefore, i really want to thank Erich Fotch who has been one of the most active developer on these OSCAR components. Actually because of the current design of OSCAR, this has been pretty simple to implement this new capabilities. I still have to stabilize and polish the code but everything should be in OSCAR trunk very soon. 

  06-09-2007:  I just checked-in new packages and few modifications into OSCAR trunk. I still have to do some testing but it seems that it is possible to deploy a Debian cluster and go up the testing step (i do not have yet a Debian package for APItest). 

  05-30-2007:  Since official packages are now available for SystemImager, i switch to Etch x86_64. This is now the only official Debian distribution supported even if the port to other Debian based distributions should be pretty simple. 

  05-30-2007:  All my patches for SystemImager-debian have been accepted into SVN trunk. It is therefore possible to create packages on both x86 and x86_64 architectures! These packages are available via our OSCAR-Debian repository: add the following entry in your '/etc/apt/sources.list': 'deb http://oscar.gforge.inria.fr/debian/ sid main'. Note that if you compare Debian packages with RPM packages there is still a difference different: packages for imagemanip and initrd-template are not available. I will focus on this point during the next few weeks. I will also create packages for Debian etch x86_64, specifically for OSCAR. 