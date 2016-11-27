---
layout: wiki
title: IndianaServers
meta: 
permalink: "wiki/IndianaServers"
category: wiki
---
<!-- Name: IndianaServers -->
<!-- Version: 8 -->
<!-- Author: dikim -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > Preparations

## Indiana University Build Servers

Indiana University has granted OSCAR developers access to 4 development boxes for building binary packages and running other tests.  If you need an account on these systems, please email us at [mailto:oscar-devel@lists.sourceforge.net oscar-devel mailing-list].  The following are the specs of the servers:

|*Hostname*|*OS*|*CPU*|*RAM*|
|oscar1.ussg.indiana.edu|RHEL4u3|Pentium 4 1.7GHz|256MB|
|oscar2.ussg.indiana.edu|RHEL3u7|Pentium 4 1.6GHz|512MB|
|oscar3.ussg.indiana.edu|SUSE10.0|Pentium 4 1.6GHz|512MB|
|oscar4.ussg.indiana.edu|FC5|Pentium 4 1.6GHz|512MB|

NOTE:
Only oscar1.ussg.indiana.edu is accessible to the IU outside network and it works as a gateway of the OSCAR devel machines.[[BR]]
(i.e., you can access the other machines after you logged in to oscar1)

For `oscar3`, you can use `yast`, a similar tool to `yum`, to install new RPM packages:


    $ sudo yast --install rpm_name

I think nobody argues against that we want to keep our build machines as stable as possible but it is possible to mess up our build machines with some careless administration of packages.[[BR]]
So, I would like to suggest the following things that may help to trace down what packages (rpms) have been installed since the fresh installation.

 * Keep notes at /usr/local/src with an obvious file name.[[BR]]
   (e.g., LIST_OF_RPMS_07jul06.txt)
 * Leave your name with your email at the top of your note[[BR]]
   (e.g., # Thu Jan 12 2006  12:09:44PM    Thomas Naughton  <naughtont@####.###>)
 * Put some comments what you have installed and list up the name of packages(rpms)


Here is a good example which is the note Thomas has left before.

    [root@oscar1 ~]# cat /usr/local/src/LIST_OF_RPMS_12jan06.txt
    # Thu Jan 12 2006  12:09:44PM    Thomas Naughton  <naughtont@####.###>
    
    
    DongInn or I used 'up2date' to install:
       - python-devel
       - mozilla, ....
       - expat-devel
    
    I installed the following SRPMS (and built/tested them):
       - apitest
       - python-elementtree (multiple versions)
       - python-twisted
    
    I installed the following RPMS:
       - apitest
       - python-elementtree
       - python-twisted
    
    
    
    AFAIK, that is all I installed and I have left them installed.  The SRPMS
    were taken in part from FC4 and other locations.
    
    --tjn
    
    [root@oscar1 ~]#

The OSCAR devel machines have setup NFS for users' /home directory and anyone who has a account for the devel machine (oscar1) can see his/her $HOME same across all the OSCAR devel machines.
