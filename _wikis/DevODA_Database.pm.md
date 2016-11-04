---
layout: wiki
title: DevODA_Database.pm
meta: 
permalink: "wiki/DevODA_Database.pm"
category: wiki
---
<!-- Name: DevODA_Database.pm -->
<!-- Version: 14 -->
<!-- Author: dikim -->

[DevelDocs] > [ODA](DevODA) > Database.pm
## Database.pm

`Database.pm`, located at the next level of the ODA hierarchy, is an[[BR]]
abstract Perl module to handle directly all the database operations under[[BR]]
the control of `oda.pm`. Many Perl subroutines defined at[[BR]]
`Database.pm` are exported so that non-database codes of OSCAR can[[BR]]
use its subroutines as if they are defined by importing `Database.pm`[[BR]]

     (e.g., use Database.pm )

For example, _get_packages_ in `Database.pm` is a subroutine[[BR]]
that the OSCAR installer can call to get the list of OSCAR packages.[[BR]]
The Perl module, `Database.pm` including the subroutine, _get_packages_,[[BR]]
looks like this:[[BR]]

    package OSCAR::Database
    use oda
    
    @export = (get_packages,
               .... );
    
    sub get_packages{
        my $ref_result = shift;
        my $sql = "SELECT package FROM Packages";
        my $error;
        my $local_result;
        my $status = ODA::query(\$sql, \$local_result,
           \$error);
        # ...translate $local_result into common
        # form and store in $ref_results...
        $status;
    }

The subroutines have been created to query or update data from or to the[[BR]]
specific database tables. For the query of data, the name of the subroutines[[BR]]
starts with _get_ and if there is an argument to set the _WHERE_ clause,[[BR]]
_with__ and the argument name are added as a suffix.  On the other hand,[[BR]]
the subroutines to update data into the tables are named starting with _set_.[[BR]]
Like the query subroutines, the updated subroutines can also add _with__[[BR]]
and the argument for the _WHERE_ clause as a suffix. There is a conventional[[BR]]
rule to set the arguments to the subroutines. The required arguments should[[BR]]
be set as the first and next argument and the optional arguments are supposed[[BR]]
to be set from the last, in the reverse order, so that the optional arguments[[BR]]
can be disregarded even though they are not given to the subroutines.[[BR]]
The usual optional arguments in `Database.pm` are _$options_ref_ and[[BR]]
_$error_strings_ref_.

The subroutines most frequently used in `Database.pm` are _do_select_[[BR]]
for querying, _do_update_ for updating, and _do_insert_ for inserting.[[BR]]
The subroutine _do_select_, internally calls the _do_query_ subroutine of[[BR]]
_oda.pm_ and transfers the return values of _do_query_ to the caller or[[BR]]
another subroutine. Like _do_select_, _do_update_ and _do_insert_ use[[BR]]
the _do_sql_command_ subroutine of _oda.pm_ to run the database works[[BR]]
at the back-end. Then, they return the signal to determine if the SQL query[[BR]]
is successfully implemented to the caller or another subroutine.[[BR]]

The source is available on the following link: [[BR]]
[https://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/lib/OSCAR/Database.pm]
----
 * [oda.pm](DevODA_oda.pm)
 * [Architecture](DevODA_architecture)
 * [Maintenance](DevODA_maintenance) of ODA
