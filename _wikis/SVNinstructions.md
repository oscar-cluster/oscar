---
layout: wiki
title: SVNinstructions
meta: 
permalink: "wiki/SVNinstructions"
category: wiki
---
<!-- Name: SVNinstructions -->
<!-- Version: 1 -->
<!-- Author: jparpail -->
[Documentations](Document) > [Developer Documentations](DevelDocs) > SVN

## How to use OSCAR Subversion repository ?

Before you begin, it is strongly recommended that you take a few moments to read the book [Versioning Control with Subversion](http://svnbook.red-bean.com).  It is a valuable resource whether you are a long time programmer or just getting started.

The OSCAR SVN Code Repository supports anonymous check-outs.  However, to check code in, you will need to have an account.  To request for an account, please email us at [mailto:oscar-devel@lists.sourceforge.net oscar-devel@lists.sourceforge.net].

You will need a [Subversion client](http://subversion.tigris.org) to check code out (_Note_: v1.2.1 has a bug with `svn st -u`, it is recommended that you use a version other than 1.2.1).  After it has been installed, we need to check which schema it supports:

    svn --version

It should look something like this:

    svn, version 1.1.4 (r13838)
       compiled Apr  2 2005, 10:37:07
    
    Copyright (C) 2000-2004 CollabNet.
    Subversion is open source software, see http://subversion.tigris.org/
    This product includes software developed by CollabNet (http://www.Collab.Net).
    
    The following repository access (RA) modules are available:
    
    * ra_dav : Module for accessing a repository via WebDAV (DeltaV) protocol.
      - handles 'http' schema
      - handles 'https' schema

If you simply want to perform anonymous check-outs, then you only need the `http` schema.  If you are a developer and need to check code in, then you will need the module which handles `https` schema as well.

If your client does not support the `https` schema, then you will need to manually build the client from source - just make sure that you configure it as follows:

    ./configure --with-ssl

Let's try to check code out...

For anonymous check-out, the command is:

    % svn co http://svn.oscar.openclustergroup.org/oscar/trunk oscar

For developers who have SVN account:

    % svn co https://svn.oscar.openclustergroup.org/svn/oscar/trunk oscar

This will check out OSCAR code from trunk and put it in a directory called `oscar` in the current working directory.

Some times you may want to just check out a branch:

 * Anonymous check-out:
   
    % svn co http://svn.oscar.openclustergroup.org/oscar/branches/branch-4-1 oscar-4.1
       ```
    
     * Developer check-out:
       ```
    % svn co https://svn.oscar.openclustergroup.org/svn/oscar/branches/branch-4-1 oscar-4.1
       ```
    
    This will check out the 4.1 branch to a local directory called `oscar-4.1`.
    
    After you have successfully checked the code out, to install OSCAR, first install the perl-Qt RPM from `$OSCAR_HOME/packages/perl-Qt/distro/` (or `$OSCAR_HOME/share/prereq/perl-Qt/distro/` in OSCAR 5.0+).  Then, execute the following command in the root directory of the check-out:
    
    ```
    # ./autogen.sh && ./configure && make install

OSCAR will be installed to `/opt/oscar` - continue the installation as usual.
