---
layout: wiki
title: DevODA_oda.pm
meta: 
permalink: "wiki/DevODA_oda.pm"
category: wiki
---
<!-- Name: DevODA_oda.pm -->
<!-- Version: 12 -->
<!-- Author: dikim -->

[DevelDocs] > [ODA](DevODA) > oda.pm
## oda.pm

The highest level of ODA hierarchy is `oda.pm`, which implements[[BR]]
the direct database connection and main database queries for the OSCAR[[BR]]
database.  The database connection is performed by Perl DBI. DBI[[BR]]
requires data source, username, password, and option arguments for the[[BR]]
DBI module, _connect_. So, the database handler is created by calling[[BR]]
the _connect_ module of DBI.  For example,[[BR]]


    $dbh = DBI->connect( $data_source, $username,
                         $password, %attr );
The main database queries consist of the two Perl subroutines on `oda.pm`:[[BR]]
_do_query_ and _do_sql_command_.[[BR]]
These subroutines can only be executed with the database connection of DBI[[BR]]
described above.[[BR]]

The _do_query_ takes any SQL string with several other arguments,[[BR]]
executes the SQL commands with given arguments, and then returns the[[BR]]
query results. It is designed to return all the possible format values[[BR]]
by generating general data format. Any statement calling the subroutine[[BR]]
_do_query_ takes return values with a consistent data format and can[[BR]]
set up the same routine of codes to handle the return values. The[[BR]]
_do_sql_command_ takes any SQL string and executes it with the DBI[[BR]]
database connection. The command does not have any return values to[[BR]]
transfer but returns the flag to determine whether the SQL string has[[BR]]
been successfully executed or not. The _do_query_ routine does not[[BR]]
call _do_sql_command_ to execute its SQL command. Instead, it[[BR]]
executes the command by its own internal codes since _do_sql_command_[[BR]]
can not treat the return values that _do_query_ needs to transfer.[[BR]]

The source is available on the following link: [[BR]]
[https://svn.oscar.openclustergroup.org/trac/oscar/browser/trunk/lib/OSCAR/oda.pm]
----
 * [Database.pm](DevODA_Database.pm)
 * [Architecture](DevODA_architecture)
 * [Maintenance](DevODA_maintenance) of ODA
