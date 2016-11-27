---
layout: wiki
title: DevODA_maintenance
meta: 
permalink: "wiki/DevODA_maintenance"
category: wiki
---
<!-- Name: DevODA_maintenance -->
<!-- Version: 10 -->
<!-- Author: dikim -->

[Documentations](Document) > [Developer Documentations](DevelDocs) > OSCAR infrastructure > [ODA](DevODA)

## Maintenance of ODA
More functionality needs to be added to `Database.pm`: the OSCAR[[BR]]
installer requires more complex database queries and needs to store more[[BR]]
detailed configuration parameters. ODA facilitates good management of[[BR]]
subroutines to make them simpler, to enable better search of[[BR]]
subroutines, and to allow easier maintenance. Some ideas to manage the[[BR]]
database modules (including `oda.pm` and `Database.pm`) in a[[BR]]
systematic and organized way follow:[[BR]]

 *Naming Rule*[[BR]]
As the current database modules use, having _get_ prefix for query[[BR]]
and _set_ prefix for update makes it easy to differentiate the two[[BR]]
database functionalities: query and update. The suffix with _with__[[BR]]
and the arguments for the _WHERE_ clause enables the expansion of[[BR]]
the basic getter or setter subroutines. It would be more convenient[[BR]]
for developers if subroutines were placed consistently.[[BR]]

 *Specialized module*[[BR]]
As OSCAR expands its area with various OSCAR sub-projects, the modules[[BR]]
of ODA will have to take care of more functionality and configurations[[BR]]
of the OSCAR main frame, including additional features of the OSCAR[[BR]]
sub-projects. The ODA modules will be more complicated and confusing if[[BR]]
all the additional funcationality for the sub-projects is added to the[[BR]]
main ODA modules. So, the new features for the sub-projects would need[[BR]]
to be in a different module file in order to differentiate from the main[[BR]]
ODA modules. On the other hand, having another directory for all the new[[BR]]
module files for the sub-projects would make the ODA module more[[BR]]
organized and keep it simpler. For instance, OSCAR Package Manager (OPM)[[BR]]
is one of the new features of OSCAR  and uses the immense database queries[[BR]]
to manage the installation of OSCAR package more flexibly according to[[BR]]
the user's needs. If OPM is ready to go to the current OSCAR framework,[[BR]]
the database module for only OPM would be named as[[BR]]
`OPM_Database.pm` and be located under the new directory,[[BR]]
Database, for only OSCAR sub-projects or additional ODA modules.[[BR]]

----
 * [oda.pm](DevODA_oda.pm)
 * [Database.pm](DevODA_Database.pm)
