---
layout: wiki
title: StartOver
meta: 
permalink: "wiki/StartOver"
category: wiki
---
<!-- Name: StartOver -->
<!-- Version: 2 -->
<!-- Author: bli -->

[Cluster Administrator Documentation](UserDocs) > Uninstalling OSCAR - starting over

# Uninstalling OSCAR - starting over

start_over behaves as designed and is easy to control once you understand what
it does. Here is an attempt of explanation.

The start_over script will try to delete all packages installed by OSCAR, thus
listed in the ODA Packages_rpmlists table.

It will also try to delete the packages which depend on the OSCAR RPMs. Not
deleting these would mean to leave these packages unusable (because their
dependencies, the OSCAR RPMs are gone).

And finally it will delete the dependencies of the OSCAR packages, as far as
they are not included in the pre_oscar.rpmlist.

So following packages will be candidates for deletion:
 A: OSCAR packages

 B: packages depending on the OSCAR packages

 C: dependencies of the OSCAR packages

If any of the candidates is leading to the deletion of a package in the
pre_oscar.rpmlist, it will be dropped from the list and left installed on the
system.

A is what we want anyway, B is what we need to delete otherwise B packages
will have unresolved dependencies, C is what we also want to delete, as these
were installed with the OSCAR packages.

If the package you have installed outside of OSCAR and after the OSCAR
installation (thus not appearing on the pre_oscar.rpmlist) is depending on any
of the packages in groups A, B or C, it will be deleted, too. If your package
is not depending on OSCAR packages (or their dependencies), it will be left on
the system.

I think the procedure is understandable and does exactly what we want. And if
you understand how it works, you can control the behavior. I warn everybody
from using the --yes option! The confirmation of the deletion is there for
exactly that purpose: look at the list of packages which will be deleted! If
you find something on it which you don't expect or don't want to be deleted,
type "no" and edit your pre_oscar.rpmlist.
