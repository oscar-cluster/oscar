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

# Copyright (c) 2003, The Board of Trustees of the University of Illinois.
#                     All rights reserved.
use strict;
use lib "/usr/lib/perl5/site_perl";
use Carp;
use vars qw(@EXPORT $VERSION @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);

# oda may or may not be installed and initialized
my $oda_available = 0;
my %options = ();
my $options_ref = \%options;
my $database_connected = 0;
use Data::Dumper;

@EXPORT = qw( database_calling_traceback
	      database_connect 
	      database_disconnect 
	      database_execute_command 
	      database_find_node_name
	      database_hostname_to_node_name
	      database_program_variable_get
	      database_program_variables_get
	      database_program_variable_put
	      database_program_variables_put
	      database_read_filtering_information
	      database_read_table_fields 
	      database_return_list
	      database_rpmlist_for_package_and_group 
	      dec_already_locked
	      locking
	      single_database_execute
	      unlock);

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

#
# Connect to the oscar database if the oda package has been
# installed and the oscar database has been initialized.
# This function is not needed before executing any ODA 
# database functions, since they automatically connect to 
# the database if needed, but it is more effecient to call this
# function at the start of your program and leave the database
# connected throughout the execution of your program.
#
# inputs:   print_errors   if defined and a list reference,
#                          put error messages into the list;
#                          if defined and a non-zero scalar,
#                          print out error messages on STDERR
#           options        options reference to oda options hash
# outputs:  status         non-zero if success

sub database_connect {
    my ( $print_errors, 
	 $passed_options_ref ) = @_;
    $options_ref = $passed_options_ref
	if defined $passed_options_ref &&
	ref($passed_options_ref) eq "HASH";
    if ( $$options_ref{debug} ) {
	my ($package, $filename, $line) = caller;
    	print "$0: in Database\:\:connect called from package=$package $filename\:$line\n";
    }

    # if the database is not already available, ...
    if ( ! $database_connected ) {

	# if oda was not installed the last time that 
	# this was called, try to load in the module again
	if ( ! $oda_available ) {
	    eval "use oda";
	    $oda_available = ! $@;
	    carp("in database_connect cannot use oda: $@") if ! $oda_available;
	}
	print "$0: database_connect now oda_available=$oda_available\n" 
	    if $$options_ref{debug};
	
	# assuming oda is available now, ...
	if ( $oda_available ) {

	    # try to connect to the database
	    my @error_strings = ();
	    my $error_strings_ref = ( defined $print_errors && 
				      ref($print_errors) eq "ARRAY" ) ?
				      $print_errors : \@error_strings;
	    if ( oda::connect( $options_ref,
			       $error_strings_ref ) ) {
		print "$0: database_connect connect worked\n" if $$options_ref{debug};
		$database_connected = 1;
	    }
	    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
		warn shift @$error_strings_ref while @$error_strings_ref;
	    }
	}
    }

    print "$0: database_connect returning database_connected=$database_connected\n" 
	if $$options_ref{debug};
    return $database_connected;
}

#
# connect to the oscar database if the oda package has been
# installed and the oscar database has been initialized
#

sub database_disconnect {

    if ( $$options_ref{debug} ) {
	my ($package, $filename, $line) = caller;
    	print "$0: in Database\:\:disconnect called from package=$package $filename\:$line\n";
    }

    # if the database is not connected, done
    return 1 if ! $database_connected;

    # disconnect from the database
    oda::disconnect( $options_ref, undef );
    $database_connected = 0;

    return 1;
}

# This function executes an oda database command, parsing
# the command from one or more string arguments, expanding
# any database shortcuts if needed. It calls oda::execute_command
# to execute a database command or shortcut, this is only needed
# to avoid having calling code have to do the conditional 
# "use OSCAR::oda" in case they are executing at a point when
# the oda has not been installed yet. For returning lists from
# exexcuted commands, see the subroutine database_return_list.
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
#         print_errors  if defined and a list reference,
#                       put error messages into the list;
#                       if defined and a non-zero scalar,
#                       print out error messages on STDERR
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
	 $print_errors ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return undef;

    # execute the command
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my $success = oda::execute_command( $options_ref,
					$command_args_ref,
					$results_ref,
					$error_strings_ref );
    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }

    # if we weren't connected to the database when called, disconnect
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return $success;
}

#
# NEST
# This is locking a single database_execute_command with some argurments
# Basically Lock -> 1 oda::execute_command -> unlock
# $type_of_lock is optional, if it is omitted, the default type of lock is "READ".
# The required argument is $tables_ref, which is the reference of the list of tables.
# The other arguments are the same as the database_execute_command.
#
sub single_database_execute {

    my ( $command_args_ref,
         $type_of_lock,
         $tables_ref,
         $results_ref,
	 $print_errors ) = @_;

    # execute the command
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my @tables = ();
    if ( (ref($tables_ref) eq "ARRAY")
        && (defined $tables_ref)
        && (scalar @$tables_ref != 0) ){
        @tables = @$tables_ref;
    } else {
        chomp(@tables = `oda list_tables`);
    }
    my $lock_type = (defined $type_of_lock)? $type_of_lock : "READ";
    # START LOCKING FOR NEST && open the database
    my %options = ();
    if(! locking($lock_type, $options_ref, \@tables, $error_strings_ref)){
        return 0;
        #die "$0: cannot connect to oda database";
    }
    my $success = oda::execute_command( $options_ref,
					$command_args_ref,
					$results_ref,
					$error_strings_ref );
    # UNLOCKING FOR NEST
    unlock($options_ref, $error_strings_ref);
    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }
    
    return $success;
}

#
# NEST
# This subroutine is renamed from database_execute_command and represents
# the $command_args_ref in the subroutine is already locked in the outer lock block.
# Basically this subroutine is the exactly same as database_execute_command
# except for its name.
#
sub dec_already_locked {

    my ( $command_args_ref,
         $results_ref,
	 $print_errors ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return undef;

    # execute the command
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my $success = oda::execute_command( $options_ref,
					$command_args_ref,
					$results_ref,
					$error_strings_ref );
    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }

    # if we weren't connected to the database when called, disconnect
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return $success;
}

# Uses the hostname command to match against the node names in the
# database, returning the matching name. Takes into account domain
# names being tacked onto the hostname output and/or the node names.
# Does not use the "nodes" shortcut, in case it is called early.
# Returns the matching node name, returns undefined if cannot find.
#
# paramaters are: print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_find_node_name {
    
    my ( $print_errors ) = @_;
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;

    # find the hostname of this machine
    my $hostname = `hostname 2>/dev/null`;
    chomp $hostname;
    my @hostname_fields = split( ' ', $hostname );
    if ( scalar @hostname_fields != 1 ) {
	push @$error_strings_ref,
	"$0: in database_find_node_name hostname command returned unknown output <$hostname>";
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	return undef;
    }

    return database_hostname_to_node_name( $hostname,
					   $print_errors );
}

# Searches the database nodes table for a record matching
# a given hostname. Takes into account domain names being 
# tacked onto the hostname output and/or the node names.
# Does not use the "nodes" shortcut, in case it is called early.
# Returns the matching node name, returns undefined if cannot find.
#
# paramaters are: hostname      hostname string
#                 print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_hostname_to_node_name {
    
    my ( $hostname, 
	 $print_errors ) = @_;
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;

    # find the name, domain, and hostname field values for all
    # of the nodes table records in the database
    my @requested_fields = qw( hostname domain );
    my $node_records_ref = database_read_table_fields( "nodes",
						       \@requested_fields,
						       undef,
						       undef,
						       $print_errors );
    return undef if ! defined $node_records_ref;
    if ( ! keys %$node_records_ref ) {
	push @$error_strings_ref,
	"$0: in database_find_node_name cannot find any node names in database";
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	return undef;
    }

    # loop through the node records ...
    foreach my $node_name ( keys %$node_records_ref ) {
	my $node_record_ref = $$node_records_ref{ $node_name };
	# match the given hostname to the hostname field
	return $node_name
	    if defined $$node_record_ref{ hostname } &&
	    $hostname eq $$node_record_ref{ hostname };
	# match the given hostname to the name field
	return $node_name
	    if $hostname eq $node_name;
	# if the given hostname includes a domain, ...
	if ( $hostname =~ /\./ ) {
	    # find the given hostname without the domain
	    my @hostname_fields = split( '.', $hostname );
	    my $hostname_without_domain = $hostname_fields[0];
	    # match the domain-less given hostname to
	    # the record hostname field
	    return $node_name 
		if exists $$node_record_ref{ hostname } &&
		$hostname_without_domain eq 
		$$node_record_ref{ hostname };
	    # match the domain-less given hostname to
	    # the record name field
	    return $node_name 
		if $hostname_without_domain eq $node_name;
	}
	# if the record hostname field includes a domain, ...
	if ( exists $$node_record_ref{ hostname } &&
	     $$node_record_ref{ hostname } =~ /\./ ) {
	    # find the hostname field without the domain
	    my @hostname_fields = 
		split( '.', $$node_record_ref{ hostname } );
	    my $hostname_without_domain = $hostname_fields[0];
	    # match the hostname to the domain-less hostname field
	    return $node_name 
		if $hostname eq $hostname_without_domain;
	}
	# if the record name field includes a domain, ...
	if ( $node_name =~ /\./ ) {
	    # find the name field without the domain
	    my @name_fields = split( '.', $node_name );
	    my $name_without_domain = $name_fields[0];
	    # match the given hostname to the domain-less
	    # name field
	    return $node_name 
		if $hostname eq $name_without_domain;
	}
    }
    
    return undef;
}

# Reads all of the values for a given program variable, returning
# them as a list. If the program name is invalid, or that variable
# does not exist for that program, a zero length list is returned.
# If there is some other error, undefined is returned.
#
# paramaters are: program       program name
#                 variable      variable name
#                 print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR
#                 verbose       if defined and non-zero, verbose output
#                 debug         if defined and non-zero, debug output

sub database_program_variable_get {
    
    my ( $program,
	 $variable,
	 $print_errors ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return undef;

    # do the database read for all of the variable values
    # for the specified program and variable, returning
    # undefined if any errors
    my @tables_fields = qw( program_variable_values
			    program_variable_values.value );
    my @wheres = ( "program_variable_values.program=$program",
		   "program_variable_values.variable=$variable" );
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my @records = ();
    if ( ! oda::read_records( $options_ref,
			      \@tables_fields,
			      \@wheres,
			      \@records,
			      1,
			      $error_strings_ref ) ) {
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	OSCAR::Database::database_disconnect() if ! $was_connected_flag;
	return undef;
    }

    # now put the values into a list
    my @values = ();
    foreach my $record_ref ( @records ) {
	push @values, $$record_ref{value}
	    if exists $$record_ref{value};
    }

    # if we weren't connected to the database when called, disconnect
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return @values;
}

# writes out values to a program variable for a given program.
# If the value passed is a reference to a list, the list members 
# are all written out to that variable, if the value passed is a
# scalar, that single value is written out to that variable.
# Any values already set for that variable are deleted first.
#
# paramaters are: program       program name
#                 variable      variable name
#                 values        single value or values list reference
#                 print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_program_variable_put {
    
    my ( $program,
	 $variable,
	 $values_ref,
	 $print_errors ) = @_;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	return undef;
    my $status = 1;

    # remove all the previous values for this variable
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my @command_results = ();
    if ( ! oda::execute_command( $options_ref,
				 "remove_program_variable $program $variable",
				 \@command_results,
				 $error_strings_ref ) ) {
	push @$error_strings_ref,
	"cannot remove old values for program $program variable $variable from the ODA database";
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	$status = 0;
    }

    # write out the new variable values ( do not bother using
    # the set_program_variable_value shortcut for single value
    # variables since we alread deleted all old values)
    if ( ! ref( $values_ref ) ) {
	my @single_value_list = ( $values_ref );
	$values_ref = \@single_value_list;
    }
    my %assigns = ( 'program'  => $program,
		    'variable' => $variable );
    foreach my $value ( @$values_ref ) {
	my @command_results = ();
	$assigns{value} = $value;
	if ( ! oda::insert_record( $options_ref,
				   "program_variable_values",
				   \%assigns,
				   undef,
				   $error_strings_ref ) ) {
	    push @$error_strings_ref, 
	    "cannot add value $value to variable $variable for program $program in the ODA database";
	    $status = 0;
	}
    }
    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }

    # if we weren't connected to the database when called, disconnect
    
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;
    
    return $status;
}

# Reads all of the program variables for a given program and returns
# them in a hash. The keys of the hash are the variable names. Each
# value in the hash is either a reference to a list of values for
# that variable (if the variable has more than one value), or the 
# scalar value for that variable (if the variable has one value).
# This function allows spaces or other white space characters to 
# be part of the variable values. If success, the hash reference is
# returned, if failure undefined is returned.
#
# paramaters are: program       program name
#                 print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_program_variables_get {
    
    my ( $program,
	 $print_errors ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return undef;

    # do the database read for all of the variable names
    # and values for the specified program, returning
    # undefined if any errors
    my @tables_fields = qw( program_variable_values
			    program_variable_values.variable
			    program_variable_values.value );
    my @wheres = ( "program_variable_values.program=$program" );
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my @records = ();
    if ( ! oda::read_records( $options_ref,
			      \@tables_fields,
			      \@wheres,
			      \@records,
			      1,
			      $error_strings_ref ) ) {
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	OSCAR::Database::database_disconnect() if ! $was_connected_flag;
	return undef;
    }

    # now translate it to a hash, with each variable name
    # being a key, and all of the each variable's values as
    # a referenced list
    my %results = ();
    foreach my $record_ref ( @records ) {
	if ( exists $$record_ref{variable} &&
	     exists $$record_ref{value} ) {
	    my $variable = $$record_ref{variable};
	    my $value = $$record_ref{value};
	    if ( ! exists $results{$variable} ) {
		my @values = ();
		$results{$variable} = \@values;
	    }
	    my $values_ref = $results{$variable};
	    push @$values_ref, $value;
	}
    }

    # now change any variable that has exactly one value
    # from a referenced list, to a scalar value
    foreach my $variable ( keys %results ) {
	my $values_ref = $results{$variable};
	$results{$variable} = $$values_ref[0]
	    if scalar @$values_ref == 1;
    }

    # if we weren't connected to the database when called, disconnect
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return \%results;
}

# writes all of the program variables for a given program that are
# passed as a hash. The keys of the hash are the variable names.
# Each value in the hash is either a reference to a list of values for
# that variable (if the variable has more than one value), or the 
# scalar value for that variable (if the variable has one value).
# Any variables and/or values not in the hash will be removed from 
# the database for that program.
#
# paramaters are: program       program name
#                 variables     reference to variables/values hash
#                 print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_program_variables_put {
    
    my ( $program,
	 $variables_ref,
	 $print_errors ) = @_;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return ( undef, undef, undef );
    my $status = 1;

    # remove all the previous variables for this program
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my @command_results = ();
    if ( ! oda::execute_command( $options_ref,
				 "remove_program_variables $program",
				 \@command_results,
				 $error_strings_ref ) ) {
	push @$error_strings_ref,
	"cannot remove old variables for program $program from the ODA database";
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	$status = 0;
    }

    # write out the new variable values ( do not bother using
    # the set_program_variable_value shortcut for single value
    # variables since we alread delete all old values)
    foreach my $variable ( keys %$variables_ref ) {
	my $values_ref = $$variables_ref{$variable};
	if ( ! ref( $values_ref ) ) {
	    my @single_value_list = ( $values_ref );
	    $values_ref = \@single_value_list;
	}
	my %assigns = ( 'program'  => $program,
			'variable' => $variable );
	foreach my $value ( @$values_ref ) {
	    my @command_results = ();
	    $assigns{value} = $value;
	    if ( ! oda::insert_record( $options_ref,
				       "program_variable_values",
				       \%assigns,
				       undef,
				       $error_strings_ref ) ) {
		push @$error_strings_ref,
		"cannot add value $value to variable $variable for program $program in the ODA database";
		if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
		    warn shift @$error_strings_ref while @$error_strings_ref;
		}
		$status = 0;
	    }
	}
    }

    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }
    
    # if we weren't connected to the database when called, disconnect

    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return $status;
}

# reads the global information used for package and rpm filtering,
# if one or more of the values can't be read they are returned 
# as undef
#
# parameters are: print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR
#
# returned values:  architecture
#                   distribution
#                   distribution_version

sub database_read_filtering_information {
    
    my ( $print_errors ) = @_;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return ( undef, undef, undef );

    # read them all in

    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;

    my @architecture_results = ();
    my $architecture = undef;
    if ( ! database_execute_command( "oscar_server_architecture",
				     \@architecture_results,
				     $print_errors ) ) {
	push @$error_strings_ref,
	"Error reading the architecture from the database";
    } elsif ( ! @architecture_results ) {
	push @$error_strings_ref,
	"No results returned reading the architecture from the database";
    } else {
	$architecture = $architecture_results[0];
    }

    my @distribution_results = ();
    my $distribution = undef;
    if ( ! database_execute_command( "oscar_server_distribution",
				     \@distribution_results,
				     $print_errors ) ) {
	push @$error_strings_ref,
	"Error reading the distribution from the database";
    } elsif ( ! @distribution_results ) {
	push @$error_strings_ref,
	"No results returned reading the distribution from the database";
    } else {
	$distribution = $distribution_results[0];
    }

    my @distribution_version_results = ();
    my $distribution_version = undef;
    if ( ! database_execute_command( "oscar_server_distribution_version",
				     \@distribution_version_results,
				     $print_errors ) ) {
	push @$error_strings_ref,
	"Error reading the distribution version from the database";
    } elsif ( ! @distribution_version_results ) {
	push @$error_strings_ref,
	"No results returned reading the distribution version from the database";
    } else {
	$distribution_version = $distribution_version_results[0];
    }

    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }
    
    # if we weren't connected to the database when called, disconnect

    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return ( $architecture,
	     $distribution,
	     $distribution_version );
}

# reads specified fields from all the records in a specified database
# table into a double deep hash with the first level of keys being
# taken fromt the "name" field for each record, with data in the first
# level of keys being pointers to hashes one per database table record,
# with the second level hashes being the requested fields with their
# data being the values in the database fields.
#
# paramaters are: table         database table name
#                 fields        pointer to requested field nanes list
#                               (if undef or empty returns all fields)
#                 wheres        pointer to where expressions
#                               (if undef all records returned)
#                 index_field   name of index field 
#                               (if undef "name" is used)
#                 print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_read_table_fields {
    
    my ( $table,
	 $requested_fields_ref,
	 $wheres_ref,
	 $passed_key_name,
	 $print_errors ) = @_;

    # if they didn't specify an index field name, use "name"
    my $key_name = ( defined $passed_key_name ) ? $passed_key_name : "name";

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return undef;
    print "entering database_read_table_fields table=$table key=$key_name\n"
	if $$options_ref{debug};

    # get a list of field names for this database table

    my %fields_in_table = ();
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    if ( ! oda::list_fields( $options_ref,
			     $table,
			     \%fields_in_table,
			     $error_strings_ref ) ) {
	push @$error_strings_ref,
	"cannot read the field names for database table <$table> from the ODA database";
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	OSCAR::Database::database_disconnect() if ! $was_connected_flag;
	return undef;
    }

    # if there isn't a key_name field in this database table, we
    # have a serious problem

    if ( ! exists $fields_in_table{$key_name} ) {
	push @$error_strings_ref, 
	"there is no <$key_name> field in database table <$table>";
	push @$error_strings_ref, 
	"Database\:\:database_read_table_fields cannot supply the data as requested";
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	OSCAR::Database::database_disconnect() if ! $was_connected_flag;
	return undef;
    }
	
    # if the caller supplied an undef or empty fields list,
    # we'll supply all fields for this database. Also, make
    # sure that the field <$key_name> is included.

    my @fields = ();
    if ( defined($requested_fields_ref) && @$requested_fields_ref ) {
	@fields = @$requested_fields_ref;
	push @fields, "$key_name"
	    if ! grep( /^$key_name$/, @fields );
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
    if ( ! oda::read_records( $options_ref,
			      \@table_fields,
			      $wheres_ref,
			      \@records,
			      1,
			      $error_strings_ref ) ) {
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	OSCAR::Database::database_disconnect() if ! $was_connected_flag;
	return undef;
    }
    # convert the array of hash pointers that read_records returned
    # into the hash of hashes format that the callers expect

    my %results = ();
    my %duplicated_name_values = ();
    my $missing_name_fields = 0;
    foreach my $record_ref ( @records ) {
	if ( exists $$record_ref{$key_name} && $$record_ref{$key_name} ne "" ) {
	    my $key = $$record_ref{$key_name};
	    if ( exists $results{$key} ) {
		$duplicated_name_values{$key} = 1;
	    } else {
		$results{$key} = $record_ref;
	    }
	} else {
	    $missing_name_fields++;
	}
    }
    foreach my $name ( sort keys %duplicated_name_values ) {
	push @$error_strings_ref,
	"There are duplicated records in database table <$table> that has the same <$key_name> field value of <$name>.";
    }
    push @$error_strings_ref,
    "Database\:\:database_read_table_fields will only return the first of each."
	if %duplicated_name_values;
    if ( $missing_name_fields ) {
	push @$error_strings_ref,
	"$missing_name_fields records from the database table <$table> are missing the <$key_name>";
	push @$error_strings_ref,
	"field and are not being returned by Database\:\:database_read_table_fields.";
    }
    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }

    # if we weren't connected to the database when called, disconnect

    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return \%results;
}

# This function executes an oda database command, parsing
# the command from one or more string arguments, expanding
# any database shortcuts if needed. It nicely returns a list
# all the result values. Note that if a returned value
# includes white space it will be seperated into multiple
# values in the returned list. If you want to read database
# values and preserve funky value characters, use the 
# database_read_table_fields function instead of this one.
#
# inputs: command_args  either a single scalar string that
#                       includes the command/shortcut and any
#                       arguments, or a reference to a list
#                       strings that include the command/shortcut
#                       and any arguments.
#         print_errors  if defined and a list reference,
#                       put error messages into the list;
#                       if defined and a non-zero scalar,
#                       print out error messages on STDERR
#
# outputs: values       The list of values returned by the 
#                       database command. If no values were
#                       returned, it returns a zero length list.
#                       If an error occurred, it returns undef.

sub database_return_list {

    my ( $command_args_ref,
	 $print_errors ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return undef;

    # execute the command
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my @command_results = ();
    my $success = oda::execute_command( $options_ref,
					$command_args_ref,
					\@command_results,
					$error_strings_ref );
    if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	warn shift @$error_strings_ref while @$error_strings_ref;
    }

    # if we weren't connected to the database when called, disconnect
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    # if the command failed, return failure
    return undef
	if ! $success;

    # otherwise, seperate out the result value words from
    # all the result records and return them as a list
    my @values = ();
    chomp @command_results;
    foreach my $result ( grep( /[^\s]/, @command_results ) ) {
	my @fields = split( '\s+', $result );
	push @values, @fields if @fields;
    }
    return @values;
}

# reads specified fields from all the records in a specified database
# table into a double deep hash with the first level of keys being
# taken fromt the "name" field for each record, with data in the first
# level of keys being pointers to hashes one per database table record,
# with the second level hashes being the requested fields with their
# data being the values in the database fields.
#
# paramaters are: package       package name
#                 group         node group name or undef if any/all
#                 print_errors  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR
#
# returns a list of rpm names, or undef if an error

sub database_rpmlist_for_package_and_group {
    
    my ( $package,
	 $group,
	 $print_errors ) = @_;

    my ($calling_package, $calling_filename, $line) = caller;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect( $print_errors ) ||
	    return undef;

    # read in all the packages_rpmlists records for this package
    my @tables_fields = qw( packages_rpmlists
			    packages_rpmlists.architecture
			    packages_rpmlists.distribution
			    packages_rpmlists.distribution_version
			    packages_rpmlists.group
			    packages_rpmlists.rpm );
    my @wheres = ( "packages.name=$package", 
		   "packages.id=packages_rpmlists.package_id" );
    my @packages_rpmlists_records = ();
    my @error_strings = ();
    my $error_strings_ref = ( defined $print_errors && 
			      ref($print_errors) eq "ARRAY" ) ?
			      $print_errors : \@error_strings;
    my $number_of_records = 0;
    if ( ! oda::read_records( $options_ref,
			      \@tables_fields,
			      \@wheres,
			      \@packages_rpmlists_records,
			      1,
			      $error_strings_ref,
			      \$number_of_records ) ) {
	push @$error_strings_ref,
	"Error reading packages_rpmlists records for package $package";
	if ( defined $print_errors && ! ref($print_errors) && $print_errors ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
        OSCAR::Database::database_disconnect() if ! $was_connected_flag;
	 return undef;
    }

    # read in the oscar global architecture, distribution, etc
    my ( $architecture,
	 $distribution,
	 $distribution_version ) =
	     database_read_filtering_information( $print_errors );
	
    # now build the matches list
    my @rpms = ();
    foreach my $record_ref ( @packages_rpmlists_records ) {
	if (
	    ( ! defined $$record_ref{architecture} ||
	      ! defined $architecture ||
	      $$record_ref{architecture} eq $architecture )
	    &&
	    ( ! defined $$record_ref{distribution} ||
	      ! defined $distribution ||
	      $$record_ref{distribution} eq $distribution )
	    &&
	    ( ! defined $$record_ref{distribution_version} ||
	      ! defined $distribution_version ||
	      $$record_ref{distribution_version} eq $distribution_version )
	    &&
	    ( ! defined $$record_ref{group} ||
	      ! defined $group ||
	      $$record_ref{group} eq $group )
	    ) { push @rpms, $$record_ref{rpm}; }
    }
	    
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return @rpms;
}


#********************************************************************#
#********************************************************************#
#                            NEST                                    #
# function to write/read lock one or more tables in the database     #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  type_of_lock              String of lock types (READ/WRITE)
#          options            optional reference to options hash
#          passed_tables_ref         reference to modified tables list
#          error_strings_ref  optional reference to array for errors
#
# outputs: non-zero if success


sub locking{
    my ( $type_of_lock,
         $options_ref,
         $passed_tables_ref,
	 $error_strings_ref,
     ) = @_;

    my @empty_tables = ();
    my $tables_ref = ( defined $passed_tables_ref ) ? $passed_tables_ref : \@empty_tables;

    my $msg = "$0: in oda:";
        $type_of_lock =~ s/(.*)/\U$1/gi;
    if( $type_of_lock eq "WRITE" ){
	    $msg .= "write_lock write_locked_tables=(";
    } elsif ( $type_of_lock eq "READ" ) {
	    $msg .= "read_lock read_locked_tables=(";
    } else {
	    return 0;
    }
	
    print $msg.
	join( ',', @$tables_ref ) . ")\n"
	if $$options_ref{debug};

    # connect to the database if not already connected
   	$database_connected ||
	    database_connect( $options_ref, $error_strings_ref ) ||
	    return 0;
    
    # find a list of all the table names, and all the fields in each table
    my $all_tables_ref = oda::list_tables( $options_ref, $error_strings_ref );
    if ( ! defined $all_tables_ref ) {
        database_disconnect( $options_ref,
                 $error_strings_ref )
            if ! $database_connected;
        return 0;
    }

    # make sure that the specified modified table names
    # are all valid table names, and save the valid ones
    my @locked_tables = ();
    foreach my $table_name ( @$tables_ref ) {
        if ( exists $$all_tables_ref{$table_name} ) {
            push @locked_tables, $table_name;
        } else {
            push @$error_strings_ref,
            "$0: table <$table_name> does not exist in " .
            "database <$$options_ref{database}>";
        }
    }

    # make the database command
    my $sql_command = "LOCK TABLES " .
        join( " $type_of_lock, ", @locked_tables ) . " $type_of_lock;" ;  
	
    my $success = 1;

    # now do the single command
    $success = 0 
    if ! oda::do_sql_command( $options_ref,
			      $sql_command,
			      "oda\:\:$type_of_lock"."_lock",
			      "$type_of_lock lock in tables (" .
			      join( ',', @locked_tables ) . ")",
			      $error_strings_ref );
    # disconnect from the database if we were not connected at start
    database_disconnect( $options_ref,
		     $error_strings_ref )
    if ! $database_connected;

    return $success;
}

#********************************************************************#
#********************************************************************#
#                            NEST                                    #
# function to unlock one or more tables in the database              #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            optional reference to options hash
#          error_strings_ref  optional reference to array for errors
#
# outputs: non-zero if success

sub unlock {
    my ( $options_ref,
	 $error_strings_ref,
     ) = @_;


    print "$0: in oda:unlock \n"
	if $$options_ref{debug};

    # connect to the database if not already connected
    $database_connected ||
	database_connect( $options_ref,
		      $error_strings_ref ) ||
	return 0;

	# make the database command
	my $sql_command = "UNLOCK TABLES ;" ;
	
    my $success = 1;

	# now do the single command
	$success = 0 
	    if ! oda::do_sql_command( $options_ref,
				      $sql_command,
				      "oda\:\:unlock",
				      "unlock the tables locked in the database",
				      $error_strings_ref );

    # disconnect from the database if we were not connected at start
    database_disconnect( $options_ref,
		     $error_strings_ref )
	if ! $database_connected;

    oda::initialize_locked_tables();

    return $success;

}

1;
