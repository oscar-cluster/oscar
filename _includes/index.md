<!-- Name: WikiStart -->
<!-- Version: 42 -->
<!-- Author: dikim -->

# What is OSCAR ?

OSCAR allows users, regardless of their experience level with a *nix environment, to install a [Beowulf type](http://beowulf.org/overview/faq.html) high performance computing cluster. It also contains everything needed to administer and program this type of HPC cluster. OSCAR's flexible package management system has a rich set of pre-packaged applications and utilities which means you can get up and running without laboriously installing and configuring complex cluster administration and communication packages. It also lets administrators create customized packages for any kind of distributed application or utility, and to distribute those packages from an online package repository, either on or off site.

OSCAR installs on top of a standard installation of a [supported Linux distribution](/wiki/DistroSupport/). It installs and configures all required software for the selected packages according to user input. Then it creates customized disk images which are used to provision the computational nodes in the cluster with all the client software and administrative tools needed for immediate use. OSCAR also includes a robust and extensible testing architecture, ensuring that the cluster setup you have chosen is ready for production.

The default OSCAR setup is generally used for scientific computing using a [message passing interface (MPI)](http://en.wikipedia.org/wiki/Message_Passing_Interface) implementation, several of which are included in the default OSCAR package set. One of OSCAR's strengths is that it is possible to install multiple MPI implementations on one cluster and switch easily between them, either at the system default level or the individual user level.

Other types of applications which use clusters of computers, such as load balancing web clusters and high availability clustering packages, would certainly be fairly easy to implement using the OSCAR package system but are outside the expertise of our current development team.

Anyone is welcome to [contribute](/wiki/DevelDocs/) to OSCAR core development, or to submit packages to be included in the default OSCAR repositories. We are a community driven project and are always on the lookout for new talent and ideas.

# How can I contribute?
Email sysadmin@ crest . iu . edu or post a message to oscar-devel@lists.sourceforge.net to get your subversion and trac account. We will send an invitation mail to let you create your own account for our systems(i.e., subversion and trac).

# Latest release

 * On May 31, 2011: [OSCAR 6.1.1](/wiki/repoTesting/)
 * On February 8, 2011: [OSCAR 6.1.0](/wiki/repoTesting/)
 * On April 8, 2010: [OSCAR 6.0.5](/wiki/repoTesting/)
 * On September 25, 2009: [OSCAR 6.0.4](/wiki/repoTesting/)
 * On May 27, 2009: [OSCAR 6.0.3](/wiki/repoTesting/)
 * On April 08, 2009: [OSCAR 6.0.2](/wiki/repoTesting/)
 * On February 06, 2009: [OSCAR 6.0.1](/wiki/repoTesting/)
 * On January 05, 2009: [OSCAR 6.0](/wiki/repoTesting/)
 * On November 12, 2006: [OSCAR 5.0](/wiki:oscar50/)

OSCAR on!

_The OSCAR Development Team_

----

[[BlogList(recent=10, max_size=500, format=float)]]
