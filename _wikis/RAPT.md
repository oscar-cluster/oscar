---
layout: wiki
title: RAPT
meta: 
permalink: "wiki/RAPT"
category: wiki
---
<!-- Name: RAPT -->
<!-- Version: 1 -->
<!-- Author: valleegr -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure 

## Management of multiple repositories for different architectures

RAPT-2.x implements a solution for the support of multiple repositories for multiple architecture (RAPT-1.x only supported a single architecture at a time). This idea is that each repo is actually an independent repo: those for a specific arch are only for this arch, and the one for common-debs is for all the architectures for which a specific arch is available.
For instance, let's say we have two arch-dependent repos: debian-4-x86_64 and debian-4-i386, and of course the common-debs repo. We generate repo meta-data as follow:
  
  - debian-4-x86_64 -> arch = amd64,
  - debian-4-i386   -> arch = i386,
  - common-debs     -> arch = amd64, i386.

Of course, that implies that the code to generate repo meta-data is more complex for Debian, we scan for arch-dependent architectures. But it is not that difficult at the end.
