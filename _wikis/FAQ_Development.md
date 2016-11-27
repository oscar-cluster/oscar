---
layout: wiki
title: faq_development
meta: 
permalink: "wiki/faq_development"
category: wiki
---
<!-- Name: faq_development -->
<!-- Version: 3 -->
<!-- Author: valleegr -->


[Documentations](Document) > [FAQ](faq)

## FAQ for Developers

### Are there any debug options for the OSCAR Wizard?

To turn on debug mode for the OSCAR Wizard, type the following in a shell before invoking the Wizard:

    export DEBUG_OSCAR_WIZARD=y

This will give you two extra options in the OSCAR Wizard:

 * Restart ./oscar_wizard ethX
   This will restart the wizard without re-running install_cluster - this is great for making GUI changes.
 * Dump Wizard Environment
   This will dump all the environment variables as seen by the Wizard.

### Are there any debug options for update-rpms?

To turn on debug mode for update-rpms, type the following in a shell prior to running update-rpms (usually means before you invoke oscar_wizard):

    export DEBUG_UPDATE_RPMS=y

Update-rpms will then provide more verbose information during execution (why certain package installation failed, etc.)

### How do I check code out of Github?

Have a look at [Git instructions](Githubinstructions).

### How do I check code out of SVN (deprecated)?

Have a look at [SVN instructions](SVNinstructions) - deprecated.

### How to revert my SVN working directory back to a clean state?

Execute the following in your SVN root to return your SVN working directory to a clean state:

    [root@oscar oscar-4.1]# make clean && make distclean

### make install on Mandriva Linux

If you are having problems running `make install` on a SVN checkout on Mandriva Linux, make sure that you have the following 2 files linked to the respective programs' latest versions, eg.:

    /etc/alternatives/aclocal -> /usr/bin/aclocal-1.7
    /etc/alternatives/automake -> /usr/bin/automake-1.7
