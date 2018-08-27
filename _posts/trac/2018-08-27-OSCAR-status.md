---
layout: blog
title: OSCAR status
meta: OSCAR status
category: trac
folder: trac
---
<!-- Name: OSCAR_status -->
<!-- Version: 1 -->
<!-- Last-Modified: 2018/08/27 11:27:06 -->
<!-- Author: olahaye74 -->

Development on OSCAR is goin on and most features works on latest rpm based distros (CentOS-7, Fedora-28).
CentOS-6 support is back since systemimager-4.9.0 beta went out.

For curious developpers that want to get involved, new git changes have been done to ease getting started.

Git pkgsrc repository has been split in order to ease maintenance of each oscar components.
Fro shell, to list all the clonable oscar components repositories, type the following command:
curl -s "https://api.github.com/users/oscar-cluster/repos?per_page=1000" | grep -w clone_url | grep -o '[^"]\+://.\+.git'|grep -Ev 'pkgsrc|tags'

There are some dockerfile that will help bootstrap the oscar build environment. When OSCAR docker image is built,
you can run it to build optional packages or to test your new package.

Currently, a few Dockerfile exists for majo distros:
http://svn.oscar.openclustergroup.org/pkgs/downloads/docker/Dockerfile_OSCAR.centos6
http://svn.oscar.openclustergroup.org/pkgs/downloads/docker/Dockerfile_OSCAR.centos7
http://svn.oscar.openclustergroup.org/pkgs/downloads/docker/Dockerfile_OSCAR.fc27
http://svn.oscar.openclustergroup.org/pkgs/downloads/docker/Dockerfile.debian8

It is easy to create a new one from one of the above. (the most up to date is the CentOS-7 one).

To build OSCAR for a specific distro:
- Download the apropried Dockerfile (e.g. Dockerfile_OSCAR.centos7) and cd to where you've stored the dockerfile.
- Run: docker build -t oscar/unstable:1. -f Dockerfile_OSCAR.centos7 .
- When process is finished successfully, run docker run -it [image_id] /bin/bash
- Upon failure during build, use docker ps -a to find the container id that failed to completely build and run: docker start -ia [container_id]

All built packages are in container path /tftpboot/oscar/[distro_id]

As this is an unstable version, there are still things that are not working as expected, and I'm still woking on fixing those last glitches.

If you need to deploy a cluster on CentOS-7, this is the only version that supports it. In that case, be aware that this is an unstable version that still have problems that will need to be fixed by hand.

