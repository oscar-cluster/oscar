package OSCAR::Database;

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.

#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.

#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Copyright 2003 NCSA
#                Neil Gorsuch <ngorsuch@ncsa.uiuc.edu>

use strict;
use vars qw(@EXPORT $VERSION @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);

# oda may or may not be installed and initialized
eval " use oda; ";
my $oda_available = ! $@;
my %oda_options = ();
my $database_available = 0;

@EXPORT = qw( database_connect 
	      database_disconnect 
	      database_execute_command 
	      database_read_table_fields 
	      database_calling_traceback );

#
# Connect to the oscar database if the oda package has been
# installed and the oscar database has been initialized.
# This function is not needed before executing any ODA 
# database functions, since they automatically connect to 
# the database if needed, but it is more effecient to call this
# function at the start of your program and leave the database
# connected throughout the execution of your program.
#
# inputs:   print_errors_flag   if defined and non-zero,
#                               print output error messages
#
# outputs:  status                 non-zero if success

sub database_connect {
    my ( $print_errors_flag ) = @_;

    # if the database is already available and connected, success
    return 1 if $database_available;

    # if oda was not installed the last time that 
    # this was called, try to load in the module again
    if ( ! $oda_available ) {
	eval "use OSCAR::oda";
	$oda_available = ! $@;
    }

    # if oda is still not installed, done with failure
    return 0 if ! $oda_available;

    # try to connect to the database
    my @error_strings = ();
    if ( oda::connect( \%oda_options,
		       \@error_strings ) ) {

	# then try to execute an oscar shortcut command
	$database_available = 
	    oda::execute_command( undef, "packages", undef, undef );

	# disconnect from the database if no shortcuts
        oda::disconnect( undef, undef )
	    if ! $database_available;
    }
    if ( defined $print_errors_flag && $print_errors_flag ) {
	warn shift @error_strings while @error_strings;
    }
    return $database_available;
}

#
# connect to the oscar database if the oda package has been
# installed and the oscar database has been initialized
#

sub database_disconnect {

    # if the database is not connected, done
    return 1 if ! $database_available;

    # disconnect from the database
    oda::disconnect( \%oda_options, undef );
    $database_available = 0;

    return 1;
}

#
# This function executes an oda database command, parsing
# the command from one or more string arguments, expanding
# any database shortcuts if needed. It calls oda::execute_command
# to execute a database command or shortcut, this is only needed
# to avoid having calling code have to do the conditional 
# "use OSCAR::oda" in case they are executing at a point when
# the oda has not been installed yet.
#
# inputs: command_args  either a single scalar string that
#                       includes the command/shortcut and any
#                       arguments, or a reference to a list
#                       strings that include the command/shortcut
#                       and any arguments.
#         results_ref   reference to a variable for the results,
#                       commands that return one or more strings
#                       will place a reference to the list of 
#                       result strings in results_ref, commands
#                       that do not return any result strings 
#                       will place the integer number of records 
#                       affected or modified in results_ref
#         print_errors  if defined and non-zero, print out
#                       error messages
#
# outputs: status       non-zero for success, note that success
#                       just means that there are no database
#                       query modification errors, the intended 
#                       result could still be in error without
#                       any database errors, the results pointed
#                       to by the results_ref variable should
#                       be checked for values, or for the correct
#                       number of records being affected

sub database_execute_command {

    my ( $command_args_ref,
         $results_ref,
	 $print_errors_flag ) = @_;

    my @error_strings = ();
    my $success = oda::execute_command( \%oda_options,
					$command_args_ref,
					$results_ref,
					\@error_strings );
    if ( defined $print_errors_flag && $print_errors_flag ) {
	warn shift @error_strings while @error_strings;
    }
    return $success;
}

#
# reads specified fields from all the records in a specified database
# table into a double deep hash with the first level of keys being
# taken fromt the "name" field for each record, with data in the first
# level of keys being pointers to hashes one per database table record,
# with the second level hashes being the requested fields with their
# data being the values in the database fields.
#
# paramaters are:   table     database table name
#                   fields    pointer to requested field nanes list
#                             (if undef or empty returns all fields)
#                   wheres    pointer to where expressions
#                             (if undef all records returned)
#                   print_err if defined and non-zero, print out
#                             error messages

sub database_read_table_fields {
    
    my ( $table,
	 $requested_fields_ref,
	 $wheres_ref,
	 $print_errors_flag ) = @_;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_available ) ||
	OSCAR::Database::database_connect() ||
	    return undef;

    # get a list of field names for this database table

    my %fields_in_table = ();
    my @error_strings = ();
    if ( ! oda::list_fields( \%oda_options,
			     $table,
			     \%fields_in_table,
			     \@error_strings ) ) {
	if ( defined $print_errors_flag && $print_errors_flag ) {
	    warn shift @error_strings while @error_strings;
	    warn "cannot read the field names for database table <$table> from the ODA database";
	}
	OSCAR::Database::database_disconnect() if $was_connected_flag;
	return undef;
    }

    # if there isn't a "name" field in this database table, we
    # have a serious problem

    if ( ! exists $fields_in_table{name} ) {
	if ( defined $print_errors_flag && $print_errors_flag ) {
	    warn "there is no <name> field in database table <$table>";
	    warn "Database\:\:database_read_table_fields cannot supply the data as requested";
	}
	OSCAR::Database::database_disconnect() if $was_connected_flag;
	return undef;
    }
	
    # if the caller supplied an undef or empty fields list,
    # we'll supply all fields for this database. Also, make
    # sure that the field <name> is included.

    my @fields = ();
    if ( defined($requested_fields_ref) && @$requested_fields_ref ) {
	@fields = @$requested_fields_ref;
	push @fields, "name"
	    if ! grep( /^name$/, @fields );
    } else {
	@fields = sort keys %fields_in_table;
    }

    # now read all the records from the packages database table,
    # this will return an array of pointers to hashes, one hash
    # for each package record with the keys being the field names
    # and the data being the field contents

    my @table_fields = ( $table );
    foreach my $field ( @fields ) {
	push @table_fields, "$table.$field";
    }
    my @records = ();
    if ( ! oda::read_records( \%oda_options,
			      \@table_fields,
			      $wheres_ref,
			      \@records,
			      1,
			      \@error_strings ) ) {
	if ( defined $print_errors_flag && $print_errors_flag ) {
	    warn shift @error_strings while @error_strings;
	}
	OSCAR::Database::database_disconnect() if $was_connected_flag;
	return undef;
    }
    # convert the array of hash pointers that read_records returned
    # into the hash of hashes format that the callers expect

    my %results = ();
    my %duplicated_name_values = ();
    my $missing_name_fields = 0;
    foreach my $record_ref ( @records ) {
	if ( exists $$record_ref{name} && $$record_ref{name} ne "" ) {
	    my $key = $$record_ref{name};
	    if ( exists $results{$key} ) {
		$duplicated_name_values{$key} = 1;
	    } else {
		$results{$key} = $record_ref;
	    }
	} else {
	    $missing_name_fields++;
	}
    }
    if ( defined $print_errors_flag && $print_errors_flag ) {
	foreach my $name ( sort keys %duplicated_name_values ) {
	    warn "There are duplicated records in database table <$table> that";
	    warn "has the same <name> field value of <$name>.";
	}
	warn "Database\:\:database_read_table_fields will only return the first of each."
	    if %duplicated_name_values;
	if ( $missing_name_fields ) {
	    warn "$missing_name_fields records from the database table <$table> are missing the <name>";
	    warn "field and are not being returned by Database\:\:database_read_table_fields.";
	}
    }

    # if we weren't connected to the database when called, disconnect

    OSCAR::Database::database_disconnect() if $was_connected_flag;

#oda::print_hash("", "Database\:\:database_read_table_fields returning", \%results);
    return \%results;
}

#
# prints a traceback of the call stack
#

sub calling_traceback {
    my $level = 1;
    my ( $package, $filename, $line, $subroutine, $hasargs, 
    $wantarray, $evaltext, $is_require, $hints, $bitmask );
    do {
	( $package, $filename, $line, $subroutine, $hasargs, $wantarray,
	  $evaltext, $is_require, $hints, $bitmask ) = caller ( $level );
	print "called from $filename\:$line $subroutine\(\)\n"
	    if defined $filename;
	$level++;;
    } while defined $filename;
}


1;
