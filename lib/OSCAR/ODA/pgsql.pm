package oda;
#
#
# Copyright (c) 2007 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#
# This is a new version of ODA
# The highest level of ODA hierarchy is oda.pm, which implements
# the direct database connection and main database queries for the OSCAR
# database.
# 
# ODA for PostgreSQL
#

use strict;
use Carp;
use DBI;
use DBD::Pg;
use Data::Dumper;
use IO::Select;
use IPC::Open3;

# Declare main variable to use on oda.pm
my $cached_all_table_names_ref = undef;
my $cached_all_tables_fields_ref = undef;
my $temp_cached_all_tables_fields = undef;

my %locked_tables = ();
my $database_connected_flag = 0;
my $database_handle;
my $database_name;
my $database_server_version = undef;

my $database = "PostgreSQL";
my @error_strings = ();
my %options = ( 'debug'         => 0,
                'field_names'   => 0,
                'functions_dir' => "",
                'raw'           => 0,
                'verbose'       => 0 );

my %unescape_fields_hash = ();

my $AUTH = 0;

$options{debug} = 1
    if (exists $ENV{OSCAR_VERBOSE} && $ENV{OSCAR_VERBOSE} == 10) ||
        $ENV{OSCAR_DB_DEBUG};

#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to connect to the database                       #
#                                                                    #
#********************************************************************#
#********************************************************************#
#
# input:  options_ref          optional reference to options hash
#         error_strings_ref    optional reference to array for errors
#
# return: non-zero if success

sub oda_connect {
    my ( $passed_options_ref, 
     $passed_error_strings_ref ) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ( $options_ref, $error_strings_ref ) = fake_missing_parameters
    ( $passed_options_ref, $passed_error_strings_ref );

    if ( $$options_ref{debug} ) {
        my ($package, $filename, $line) = caller;
        print_hash( "", "in oda::oda_connect called from package=$package $filename\:$line database_connected_flag=$database_connected_flag passed_options_ref=",
                $passed_options_ref );
        print_hash( "", "in oda::oda_connect options_ref=", $options_ref );
    }

    # if we're connected to the wrong database, disconnect from it first
    if ( $database_connected_flag &&
     $database_name ne $$options_ref{database} ) {
        print( "DB_DEBUG>$0:\n====> in oda::oda_connect disconnecting from database $database_name\n")
            if $$options_ref{debug};
        print( "DB_DEBUG>$0:\n====> executing on database <$database_name> command <DISCONNECT>\n")
            if $$options_ref{verbose};
        oda::oda_disconnect( $options_ref,
                 $error_strings_ref );
    }

        # if we need to connect, do so
    if ( ! $database_connected_flag ) {

        my $connect_string = "DBI\:$$options_ref{type}\:dbname=$$options_ref{database}";
        $connect_string = $connect_string . ";host=$$options_ref{host}" if
            exists $$options_ref{host} && 
            defined $$options_ref{host} &&
            $$options_ref{host} ne "localhost";
        print "DB_DEBUG>$0:\n====> in oda\:\:oda_connect connnecting to database <$$options_ref{database}> as user <$$options_ref{user}>, password <$$options_ref{password}> using connect argument <$connect_string>\n"
            if $$options_ref{debug};
        print "DB_DEBUG>$0:\n====> executing on database <$$options_ref{database}> command <CONNECT> as user <$$options_ref{user}>, password <$$options_ref{password}>\n"
            if $$options_ref{verbose};
        if ( $database_handle = 
             DBI->connect($connect_string,    
                  $$options_ref{user},
                  $$options_ref{password},
                  { RaiseError => 0, PrintError => 1 }) ) {
            $database_connected_flag = 1;
            $database_name = $$options_ref{database};
            print( "DB_DEBUG>$0:\n====> in oda::oda_connect connected to database <$$options_ref{database}>\n")
            if $$options_ref{debug};
            $database_server_version = database_server_version( $options_ref );
            $cached_all_table_names_ref = undef;
            $cached_all_tables_fields_ref = undef;

            # Set AUTOCOMMIT = 1
            # This protects auto lock-release when there is anther lock
            # to release a previous lock unexpectedly.
            $database_handle->{AutoCommit} = 1;
        } else {
            push @$error_strings_ref,
            "Cannot connect to database <$$options_ref{database}> as user <$$options_ref{user}>";
        }
    }

    return $database_connected_flag;
}


#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to disconnect from the database                  #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options             reference to options hash
#          error_strings_ref   optional reference to array for errors
#
# return: non-zero if success

sub oda_disconnect {
    my ( $passed_options_ref, 
	 $passed_error_strings_ref ) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ($options_ref, $error_strings_ref) =
	fake_missing_parameters($passed_options_ref,
				$passed_error_strings_ref);

    if ($$options_ref{debug}) {
	my ($package, $filename, $line) = caller;
        print "DB_DEBUG>$0:\n====> in oda\:\:oda_disconnect called from package=$package $filename\:$line\n";
    }

    # reset any caches
    $cached_all_table_names_ref = undef;
    $cached_all_tables_fields_ref = undef;

    if ( ! $database_connected_flag ) {
	push @$error_strings_ref, 
	"This program is not connected to a database";
	return 0;
    }

    print "DB_DEBUG>$0:\n====> in oda\:\:oda_disconnect disconnnecting\n"
	if $$options_ref{debug};
    print "DB_DEBUG>$0:\n====> executing on database <$$options_ref{database}> command <DISCONNECT>\n"
	if $$options_ref{verbose};
    $database_handle->disconnect();
    $database_connected_flag = 0;
    $database_server_version = undef;
    return 1;
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to list all database names                       #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            reference to options hash
#          database_ref       reference to results list
#          error_strings_ref  optional reference to array for errors
#
# outputs: non-zero if success

sub list_databases {
    my ($passed_options_ref,
	$databases_ref,
	$passed_error_strings_ref) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ($options_ref, $error_strings_ref) =
	fake_missing_parameters($passed_options_ref,
				$passed_error_strings_ref);

    # clear out the passed by reference result list/hash
    if (ref($databases_ref) eq "HASH") {
        %$databases_ref = ();
    } else {
        @$databases_ref = ();
    }

    my $root_pass = $options{password} if $AUTH || &check_root_password;

    chomp(my @dbs = `PGPASSWORD='$root_pass' psql -U postgres -t -l | awk '{print \$1}'`);
    if ( @dbs ) {
        print( "DB_DEBUG>$0:\n====> in oda::list_databases succeeded returned <@dbs>\n")
            if $$options_ref{debug};
        foreach my $db (@dbs){
            if ( !( $db =~ /^$/) ){
                if ( ref($databases_ref) eq "HASH" ){
                    $$databases_ref{$db} = 1;
                }else{
                    push @$databases_ref, $db;
                }
            }
        }
        # PostgreSQL uses its default database postgres if a database is
        # not specified.
        # This is added for just convenience 
        if (ref($databases_ref) eq "HASH" && !$$databases_ref{postgres}){
            my $createdb_cmd;
            if ( !($createdb_cmd = `which createdb 2> /dev/null`) ) {
                push @$error_strings_ref,
                    "DB_DEBUG>$0:\n====> Looks like pgsql is not installed:\n$DBI::errstr";
                return 0;
            }
            chomp($createdb_cmd);
            my $cmd = "PGPASSWORD='$root_pass' $createdb_cmd -U postgres postgres";
            system($cmd);
            if ( $? ){
                push @$error_strings_ref,
                    "DB_DEBUG>$0:\n====> failed to create database for user " .
                    "$$options_ref{user}:\n$DBI::errstr";
                return 0;
            }
        }
    } else {
        push @$error_strings_ref,
        "DB_DEBUG>$0:\n====> _ListDBs call to list databases failed:\n$DBI::errstr";
            return 0;
    }

    return 1;
}
    
#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to list the table names in a database            #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            reference to options hash
#          error_strings_ref  optional reference to array for errors
#
# outputs: tables_ref         reference to table names hash

sub list_tables {
    my ( $passed_options_ref,
     $passed_error_strings_ref ) = @_;

    # if we still have a valid cache, return that
    return $cached_all_table_names_ref
    if defined $cached_all_table_names_ref;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ( $options_ref, $error_strings_ref ) = fake_missing_parameters
    ( $passed_options_ref, $passed_error_strings_ref );

    # clear out a new table names list
    my @table_names = ();

    # connect to the database if not already connected
    ( my $was_connected_flag = $database_connected_flag ) ||
        oda::oda_connect( $options_ref, $error_strings_ref ) ||
    return undef;

    # get the list of tables
    print "DB_DEBUG>$0:\n====> executing on database <$$options_ref{database}> command <SHOW TABLES>\n"
        if $$options_ref{verbose};
    my $cmd ="PGPASSWORD='$$options_ref{password}' psql -U $$options_ref{user} -d $$options_ref{database} -t -c '\\d'";
    chomp(@table_names = `$cmd | awk '{print \$3}'`);

    # disconnect from the database if we were not connected at start
    oda::oda_disconnect( $options_ref,
             $error_strings_ref )
    if ! $was_connected_flag;

    # if the tables list retrieval worked, copy the results
    # into the cached list and return the list pointer,
    # otherwise output an error message and return failure
    if ( @table_names ) {
    my %tables = ();
    foreach my $table_name ( @table_names ) {
        $tables{$table_name} = 1 if  !$table_name =~ /^$/;
    }
    $cached_all_table_names_ref = \%tables;
    print_hash( "", "in oda::list_tables new cached_all_table_names_ref",
            $cached_all_table_names_ref )
        if $$options_ref{debug};
    return $cached_all_table_names_ref;
    } else {
    push @$error_strings_ref,
    "DB_DEBUG>$0:\n====> retrieving list of tables in database <$$options_ref{database}> failed:\n$DBI::errstr";
    return undef;
    }
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to list the fields names in a database table     #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options        reference to options hash
#          table          name of table
#          fields_ref     reference to results list or hash
#          errors         optional reference to array for errors
#

sub list_fields{
    my ( $passed_options_ref,
         $table,
         $fields_ref,
         $passed_error_strings_ref ) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ( $options_ref, $error_strings_ref ) = fake_missing_parameters
    ( $passed_options_ref, $passed_error_strings_ref );

    #oda_connect($options_ref,$error_strings_ref);

    my $cmd ="PGPASSWORD='$$options_ref{password}' psql -U $$options_ref{user} -d $$options_ref{database} -t -c '\\d $table'";
    chomp(my @field_names = `$cmd | awk '{print \$1}'`);
    print "DB_DEBUG>$0:\n====> in oda::list_fields SQL:$cmd\n" if $$options_ref{debug};

    #oda_disconnect($options_ref,$error_strings_ref);

    foreach my $field (@field_names){
        $$fields_ref{$field} = "Not assigned";
    }

    # if fields_ref is defineds, copy the results
    # into the cached list and return the list pointer,
    # otherwise output an error message and return failure
    print "DB_DEBUG>$0:\n====> oda::list_fields: making a list of fields of the table($table)\n"
        if $$options_ref{verbose};
    if ( defined $fields_ref ) {
        $$cached_all_tables_fields_ref{$table} = $fields_ref;
        print_hash( "", "in oda::list_tables new cached_all_tables_fields_ref",
            $cached_all_tables_fields_ref )
        if $$options_ref{debug};
        return $cached_all_tables_fields_ref;
    } else {
        push @$error_strings_ref,
        "DB_DEBUG>$0:\n====> retrieving list of tables in database <$$options_ref{database}> failed:\n$DBI::errstr";
        return undef;
    }
    return 1;
}


#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to return the database server version            #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            optional reference to options hash
#          error_strings_ref  optional reference to array for errors

sub database_server_version {
    my ($passed_options_ref,
	$passed_error_strings_ref) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ($options_ref, $error_strings_ref) =
	fake_missing_parameters($passed_options_ref,
				$passed_error_strings_ref);

    # if we are already connected to the database, and the
    # server version has already been read and saved, return
    # the saved value
    if ($database_connected_flag && 
	defined $database_server_version) {
	print "DB_DEBUG>$0:\n====> in oda\:\:database_server_version returning saved <$database_server_version>\n"
	    if $$options_ref{debug};
	return $database_server_version;
    }

    # reset the global server version variable, this gets reset
    # by disconnecting anyway, but better to be safe than sorry
    $database_server_version = undef;

    # connect to the database if not already connected
    (my $was_connected_flag = $database_connected_flag) ||
	oda::oda_connect($options_ref,$error_strings_ref) ||
	return $database_server_version;

    # get the version from the database server
    my $sql_command = "SELECT version\(\);";
    print "DB_DEBUG>$0:\n====> in oda\:\:database_server_version sql_command=<$sql_command>\n"
        if $$options_ref{debug};
    print "DB_DEBUG>$0:\n====> executing on database <$$options_ref{database}> command <$sql_command>\n"
        if $$options_ref{verbose};
    my $statement_handle = $database_handle->prepare( $sql_command );
    if (!$statement_handle) {    
	push @$error_strings_ref,
	"error preparing sql statement <$sql_command> on database <$$options_ref{database}>:\n$DBI::errstr";
	oda::oda_disconnect($options_ref, $error_strings_ref)
	    if !$was_connected_flag;
	return $database_server_version;
    }
    if (!$statement_handle->execute()) {
	push @$error_strings_ref,
	"error executing sql statement <$sql_command> on database <$$options_ref{database}>:\n$DBI::errstr";
	oda::oda_disconnect($options_ref, $error_strings_ref)
	    if !$was_connected_flag;
	return $database_server_version;
    }
    my $results_array_ref = $statement_handle->fetchall_arrayref;
    if ($$options_ref{debug}) {
	print "DB_DEBUG>$0:\n====> in oda\:\:database_server_version fetchall_arrayref returned: (\n";
	foreach my $list_ref ( @$results_array_ref ) {
	    print "DB_DEBUG>$0:\n====> in oda\:\:database_server_version     (" .
		join( ',', @$list_ref ) . 
		")\n";
	}
    }
    if ($statement_handle->err) {
	push @$error_strings_ref,
	"error reading database server version from database <$$options_ref{database}>:\n$DBI::errstr";
	oda::oda_disconnect($options_ref, $error_strings_ref)
	    if !$was_connected_flag;
	return $database_server_version;
    }
    #EF# attempt to fix bug #279
    $statement_handle->finish();

    # disconnect from the database if we were not connected at start
    oda::oda_disconnect($options_ref, $error_strings_ref)
	if !$was_connected_flag;

    # if the server version request worked, copy the result
    # into the global variable
    if (defined $results_array_ref && @$results_array_ref) {
	my $record_0_ref = $$results_array_ref[0];
	$database_server_version = $$record_0_ref[0];
	print "DB_DEBUG>$0:\n====> in oda\:\:database_server_version returning saved <$database_server_version>\n"
	    if $$options_ref{debug};
    } else {
	push @$error_strings_ref,
	"DB_DEBUG>$0:\n====> retrieving database server version failed: unknown return format";
    }
    return $database_server_version;
}


#********************************************************************#
#********************************************************************#
#                                                                    #
# internal function to fill in any missing function parameters       #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            optional reference to options hash
#          error_strings_ref  optional reference to array for errors

sub fake_missing_parameters {
    my ($passed_options_ref,
	$passed_error_strings_ref) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set

    my @ignored_error_strings;
    my $error_strings_ref = (defined $passed_error_strings_ref) ? 
	$passed_error_strings_ref : \@ignored_error_strings;

    my $options_ref;
    if (defined $passed_options_ref) {
	$options_ref = $passed_options_ref;
    } else {
	$options_ref = \%options;
    }
    set_option_defaults($options_ref)
	if !$$options_ref{defaulted};

    return ( $options_ref,
         $error_strings_ref );
}


#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to set command line type options that are not    #
# already set to default values                                      #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options_ref           reference to options hash
#
# outputs: non-zero if success


sub set_option_defaults {
    my ( $options_ref ) = @_;

    # if the caller didn't specify a host, and there is a
    # file named /etc/odaserver take the host name from that,
    # or set the host to localhost
    if (!exists $$options_ref{host}) {
	if (-r "/etc/odaserver") {
	    if (!open( SERVERFILE, "/etc/odaserver")) {
		print "DB_DEBUG>$0:\n====> failed to oda server file /etc/odaserver\n";
	    } else {
		my @lines = <SERVERFILE>;
		close(SERVERFILE);
		chomp @lines;
		if (scalar @lines != 1) {
		    print "DB_DEBUG>$0:\n====> oda server file /etc/odaserver needs only one line\n";
		} else {
		    my @fields = split( /\s+/, $lines[0] );
		    if (scalar @fields != 1) {
			print "DB_DEBUG>$0:\n====> oda server file /etc/odaserver needs only one word\n";
		    } else {
			$$options_ref{host} = $fields[0];
		    }
		}
	    }
	}
	$$options_ref{host} = "localhost" 
	    if !exists $$options_ref{host};
	print "DB_DEBUG>$0:\n====> in set_option_defaults setting host = $$options_ref{host}\n"
	    if $$options_ref{debug};
    }

    # if the caller didn't specify a port, set to 5432
    if (!exists $$options_ref{port}) {
	$$options_ref{port} = 5432;
	print "DB_DEBUG>$0:\n====> in set_option_defaults setting port = $$options_ref{port}\n"
	    if $$options_ref{debug};
    }

    # if the caller didn't specify the database name/location,
    # set it to oscar
    if (!exists $$options_ref{database}) {
	$$options_ref{database} = "oscar";
	print "DB_DEBUG>$0:\n====> in set_option_defaults setting database = $$options_ref{database}\n"
	    if $$options_ref{debug};
    }

    # if the caller didn't specify the database type,
    # set it to mysql
    if (!exists $$options_ref{type}) {
	$$options_ref{type} = "Pg";
	print "DB_DEBUG>$0:\n====> in set_option_defaults setting type = $$options_ref{type}\n"
	    if $$options_ref{debug};
    }

    # if the caller didn't specify a database user id, ...
    if (!exists $$options_ref{user}) {

	# if we are root accessing the database server
	# on the local machine, set up for read/write access,
	# otherwise, set up for anonymous read-only access
	if (! $>) {
	    $$options_ref{user} = "oscar"
		if !defined $$options_ref{password};
	} else {
	    $$options_ref{user} = "anonymous";
	}
	print "DB_DEBUG>$0:\n====> in set_option_defaults setting user = $$options_ref{user}\n"
	    if $$options_ref{debug};
	print "DB_DEBUG>$0:\n====> in set_option_defaults setting password = $$options_ref{password}\n"
	    if $$options_ref{debug};
    }

    # if the caller didn't specify a database user password, ...
    if (!exists $$options_ref{password}) {

        # if we are root accessing the database server,
        # use the password defined in the /etc/odapw 
        # file if there, otherwise, set the password to undef
        $$options_ref{password} = undef;
        if (! $>) {
            if ( -r "/etc/odapw" ) {
                if (!open( PWFILE, "/etc/odapw")) {
                    print "DB_DEBUG>$0:\n====> failed to open "
                     . "password file /etc/odapw\n";
                } else {
                    my @lines = <PWFILE>;
                    close(PWFILE);
                    chomp @lines;
                    if (scalar @lines != 1) {
                        print "DB_DEBUG>$0:\n====> password file "
                        . "/etc/odapw needs only one line\n";
                    } else {
                        my @fields = split( /\s+/, $lines[0] );
                        if (scalar @fields != 1) {
                            print "DB_DEBUG>$0:\n====> password file "
                          . "/etc/odapw needs only one word\n";
                        } else {
                            $$options_ref{password} = $fields[0];
                            print "DB_DEBUG>$0:\n====> in "
                          . "set_option_defaults setting password "
                          . "= $$options_ref{password}\n"
                                if $$options_ref{debug};
                        }
                    }
                }
            }
        }
    }
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to print a dump of a hash                        #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  $leading_spaces    some description(string) about the hash
#          $name              name(string) for the hash
#          $hashref           reference of the hash to print out
#
# outputs: prints out the hash contents


sub print_hash {
    my ($leading_spaces, $name, $hashref) = @_;
    print "DB_DEBUG>$0:\n====> in oda::print_hash\n-- $leading_spaces$name ->\n";
    foreach my $key (sort keys %$hashref) {
        my $value = $$hashref{$key};
        if (ref($value) eq "HASH") {
            print_hash(  "$leading_spaces    ", $key, $value );
        } elsif (ref($value) eq "ARRAY") {
            print "-- $leading_spaces    $key => (";
            print join(',', @$value);
            print ")\n";
        } elsif (ref($value) eq "SCALAR") {
            print "-- $leading_spaces    $key is a scalar ref\n";
            print "-- $leading_spaces    $key => $$value\n";
        } else {
            $value = "undef" unless defined $value;
            print "-- $leading_spaces    $key => <$value>\n";
        }
    }
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# external function to do an sql command                             #
#                                                                    #
#********************************************************************#
#********************************************************************#
#
# input:  options_ref        options hash pointer or undef for none passed
#         sql_command        sql command to do
#         caller_string      short description of the query
#         failure_string     error message to transfer from caller to oda
#         error_strings_ref  error strings list pointer or undef
#
# return: success            non-zero for success

sub do_sql_command {
    my ($passed_options_ref,
	$sql_command,
	$passed_caller_string,
	$passed_failure_string,
	$passed_error_strings_ref) = @_;
    
    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ($options_ref, $error_strings_ref) =
	fake_missing_parameters($passed_options_ref,
				$passed_error_strings_ref);
    my $caller_string = (defined $passed_caller_string) ?
	$passed_caller_string : "unspecified";
    my $failure_string = (defined $passed_failure_string) ?
	$passed_failure_string : "unspecified";
    
    my @entries_sql = split(/ /, $sql_command);
    %locked_tables = ();
    if( (scalar @entries_sql != 0) && $entries_sql[0] eq "LOCK" ){
        my %filters = ("LOCK" =>1,
		       "TABLES" =>1,
		       "READ,"  => 1,
		       "WRITE," => 1,
		       "READ;"  => 1,
		       "WRITE;" => 1,
		       );
        $temp_cached_all_tables_fields = $cached_all_tables_fields_ref;
        $cached_all_tables_fields_ref = undef;                
        foreach my $entry (@entries_sql){
            if( ! exists $filters{$entry} ){
                $locked_tables{$entry} = 1;
            }
        }
    }
    # connect to the database if not already connected
    ( my $was_connected_flag = $database_connected_flag ) ||
	oda_connect( $options_ref,
		     $error_strings_ref ) ||
		     return 0;
    print "DB_DEBUG>$0:\n====> in oda\:\:do_sql_command" .
	" sql_command=<$sql_command>" .
	" caller=<$caller_string>" .
	" failure=<$failure_string>" .
	"\n"
	if $$options_ref{verbose} || $$options_ref{debug};
    
    # Do the sql command via perl DBI
    my $row = $database_handle->do($sql_command);
    if ( $DBI::errstr ) {
        push @$error_strings_ref,
        "Error message: $failure_string in database <$$options_ref{database}>: $DBI::errstr";
        push @$error_strings_ref, 
        "$0: SQL command that failed was: <$sql_command>";
        warn shift @$error_strings_ref while @$error_strings_ref;

        oda_disconnect( $options_ref,
                 $error_strings_ref )
        if ! $was_connected_flag;
        return 0;
    } else {
        # Clear off the error strings in the error array.
        shift @$error_strings_ref while @$error_strings_ref;
        return 1;
    }
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# internal function to query data from database via an sql command   #
#                                                                    #
#********************************************************************#
#********************************************************************#
#
# input:  options_ref        options hash pointer or undef for none passed
#         sql_command        sql command to do
#         error_strings_ref  error strings list pointer or undef
#
# return: success            non-zero for success


sub do_query {
    my ($passed_options_ref,
	$sql_command,
	$results_ref,
	$passed_error_strings_ref,
	$passed_number_of_records_ref) = @_;
    
    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ( $options_ref, $error_strings_ref ) =
	fake_missing_parameters($passed_options_ref,
				$passed_error_strings_ref);
    my $ignored_number_of_records;
    my $number_of_records_ref = ( defined $passed_number_of_records_ref ) ? 
	$passed_number_of_records_ref : \$ignored_number_of_records;
    
    # initialize output stuff
    $$number_of_records_ref = 0;

    # connect to the database if not already connected
    ( my $was_connected_flag = $database_connected_flag ) ||
	oda_connect( $options_ref,
		     $error_strings_ref ) ||
		     return 0;

    print "DB_DEBUG>$0:\n====> in oda\:\:do_query: executing on database"
        . " <$$options_ref{database}> command <$sql_command>\n"
        if $$options_ref{verbose};
    my $statement_handle = $database_handle->prepare($sql_command);
    if (!$statement_handle) {    
        push @$error_strings_ref,
            "error preparing sql statement <$sql_command> on database "
            . "<$$options_ref{database}>:\n$DBI::errstr";
        oda_disconnect($options_ref, $error_strings_ref)
            if !$was_connected_flag;
        return 0;
    }
    if (!$statement_handle->execute()) {
        push @$error_strings_ref,
            "error executing sql statement <$sql_command> on database "
            . "<$$options_ref{database}>:\n$DBI::errstr";
        oda_disconnect( $options_ref, $error_strings_ref )
            if !$was_connected_flag;
        return 0;
    }
    
    while (my $result_hash_ref = 
	   $statement_handle->fetchrow_hashref('NAME_lc')) {
        $$number_of_records_ref++;
        foreach my $field_name (sort keys %$result_hash_ref) {

	    #TJN: hack to skip empty values in the data
	    # see Bug#1037823 'lots of warning msgs in log from oda.pm'
            if (defined($$result_hash_ref{$field_name})  
		and $$result_hash_ref{ $field_name } =~ /^\'.*\'$/ ) {
                $$result_hash_ref{ $field_name } =~ s/^\'//;
                $$result_hash_ref{ $field_name } =~ s/\'$//;
            }
        }
        push @$results_ref, $result_hash_ref;
    }

    if ($DBI::err) {
        push @$error_strings_ref,
            "Error message: in database <$$options_ref{database}>: "
            . "$DBI::errstr";
        push @$error_strings_ref, 
            "SQL command that failed was: <$sql_command>";
        warn shift @$error_strings_ref while @$error_strings_ref;
        oda_disconnect( $options_ref, $error_strings_ref )
            if ! $was_connected_flag;
        return 0;
    } 

    #EF# attempted fix for bug #279
    $statement_handle->finish();

    if ( ref($error_strings_ref) eq "ARRAY" ){
        my $num = scalar @$error_strings_ref;
        if( $num != 0 ){
            shift @$error_strings_ref while @$error_strings_ref;
        }
    }
    # disconnect from the database if we were not connected at start
    oda_disconnect($options_ref, $error_strings_ref)
	if !$was_connected_flag;

    if ($$options_ref{debug} || $$options_ref{verbose}) {
        print "DB_DEBUG>$0:\n====> in oda\:\:do_query" .
	    " sql_command=<$sql_command>" .
	    "\n";
        print( "DB_DEBUG>$0:\n====> in oda\:\:do_query returning:\n" );
        print Dumper( $results_ref );
    }
    return 1;
}



#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to create a database                             #
#                                                                    #
#********************************************************************#
#********************************************************************#
#
# input:  options_ref          optional reference to options hash
#         error_strings_ref    optional reference to array for errors
#
# return: non-zero if success

sub create_database {
    my ($passed_options_ref, $passed_error_strings_ref) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ($options_ref, $error_strings_ref) =
	fake_missing_parameters($passed_options_ref,
			            	$passed_error_strings_ref);

    if ($database_connected_flag) {
        push @$error_strings_ref,
        "This program is already connected to the database";
        return 0;
    }

    # even though the user/password may be all right, we require
    # database creation to be done only by root
    if ( $> ) {
        push @$error_strings_ref,
            "You need to be root to create the database.\n";
        return 0;
    }

    my $status = reset_password($options_ref, $error_strings_ref);

    return $status if !$status;

    my $createdb_cmd;
    if ( !($createdb_cmd = `which createdb 2> /dev/null`) ) {
        push @$error_strings_ref,
	        "DB_DEBUG>$0:\n====> Looks like pgsql is not installed:\n$DBI::errstr";
        return 0;
    }
    chomp($createdb_cmd);
    my $cmd = "$createdb_cmd -U $$options_ref{user} $$options_ref{database}";
    $cmd = "PGPASSWORD='$$options_ref{password}' " . $cmd if $AUTH;
    system($cmd);
    if ( $? ){
        push @$error_strings_ref,
            "DB_DEBUG>$0:\n====> failed to create database for user " .
            "$$options_ref{user}:\n$DBI::errstr";
        return 0;
    }
    print( "DB_DEBUG>$0:\n====> in oda\:\:create_database createdb " . 
	   "<$$options_ref{database}> with master user " .
	   "<$$options_ref{user}> succeeded\n" )
	if $$options_ref{debug};

    return 1;
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to reset a database password                     #
#                                                                    #
#********************************************************************#
#********************************************************************#
#
# input:  options_ref          optional reference to options hash
#         error_strings_ref    optional reference to array for errors
#
# return: non-zero if success

sub reset_password{
    my ($options_ref, $error_strings_ref) = @_;

    chomp(my $pw =  `cat /etc/odapw`);
    $$options_ref{password} = $pw if $$options_ref{password} ne $pw;

    my $root_pass = $options{password} 
        if $AUTH || &check_root_password; 

    my $cmd_string = "psql -U postgres -d postgres";
    $cmd_string = "PGPASSWORD='$root_pass' " . $cmd_string if $root_pass;
    my $create_cmd = " -c \"CREATE USER $$options_ref{user} PASSWORD "
        . "'$$options_ref{password}' CREATEDB NOCREATEUSER\" ";
    my $alter_cmd = " -c \"ALTER USER $$options_ref{user} PASSWORD "
        . "'$$options_ref{password}' CREATEDB NOCREATEUSER\" ";

    # Create an oscar pgsql user first. If it already exists, alter the
    # user properties
    $create_cmd = $cmd_string . $create_cmd;
    system($create_cmd);
    if ( $? ){
        $alter_cmd = $cmd_string . $alter_cmd;
        system($alter_cmd);
        if ( $? ){
            push @$error_strings_ref,
                "DB_DEBUG>$0:\n====> failed to reset password for user " .
                "$$options_ref{user}:\n$DBI::errstr";
            return 0;
        }
    }

    #
    # I will put the code to create anonymous user account here  if necessary.
    #
        
    return 1;
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to remove ODA including the entire database and  #
# the oda user (oscar)                                               #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            reference to options hash
#          error_strings_ref  optional reference to array for errors
#
# return: database type(Pg) if success

sub remove_oda {
    my ($passed_options_ref, $passed_error_strings_ref) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ($options_ref, $error_strings_ref) =
	fake_missing_parameters($passed_options_ref,
                            $passed_error_strings_ref);

    if ($database_connected_flag) {
        push @$error_strings_ref,
            "This program is still connected to a database";
        return 0;
    }

    # even though the user/password may be all right, we require
    # database dropping to be done only by root
    if ( $> ) {
        print "You need to be root to drop the database.\n";
        return 0;
    }


    my $root_pass = "";
    $root_pass = $options{password} if $AUTH || &check_root_password; 
    if ( $root_pass ){
        $root_pass = "PGPASSWORD='$root_pass' ";
    }
    

    drop_database($options_ref, $error_strings_ref);

    # Revoke all the privileges of oscar user and remove oscar user from
    # pgsql database
    my $cmd_string = "dropuser -U postgres $$options_ref{user}";
    $cmd_string = $root_pass . $cmd_string if $root_pass;

    return 0 if !do_shell_command($options_ref, $cmd_string);
    
    print "DB_DEBUG>$0:\n====> in oda::drop_database revoking oscar "
         ."user's privileges is succeeded\n"
        if $$options_ref{debug} || $$options_ref{verbose};

    # since we successfully dropped the entire database,
    # reset the cache of table names and 
    # reset the cache of table/field names
    $cached_all_table_names_ref = undef;
    $cached_all_tables_fields_ref = undef;

    return $$options_ref{type};
}

#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to drop (delete) the entire database             #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            reference to options hash
#          error_strings_ref  optional reference to array for errors
#
# return: non-zero if success

sub drop_database {
    my ($passed_options_ref, $passed_error_strings_ref) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ($options_ref, $error_strings_ref) =
	fake_missing_parameters($passed_options_ref,
                            $passed_error_strings_ref);

    if ($database_connected_flag) {
        push @$error_strings_ref,
            "This program is still connected to a database";
        return 0;
    }

    # even though the user/password may be all right, we require
    # database dropping to be done only by root
    if ( $> ) {
        print "You need to be root to drop the database.\n";
        return 0;
    }


    my $root_pass = "";
    $root_pass = $options{password} if $AUTH || &check_root_password; 
    if ( $root_pass ){
        $root_pass = "PGPASSWORD='$root_pass' ";
    }
    
    my $dropdb_cmd;
    if ( !($dropdb_cmd = `which dropdb 2> /dev/null`) ) {
        push @$error_strings_ref,
	        "DB_DEBUG>$0:\n====> Looks like pgsql is not installed:\n"
            . "$DBI::errstr";
        return 0;
    }
    chomp($dropdb_cmd);
    my $cmd = "$dropdb_cmd -U $options{user} $$options_ref{database}";
    $cmd = $root_pass . $cmd if $root_pass;
    if ( $$options_ref{debug} ) {
        print "DB_DEBUG>$0:\n====> in oda::drop_database install_driver"
            . " succeeded\n";
        print "DB_DEBUG>$0:\n====> in oda::drop_database about to run $cmd";
    }

    if (! do_shell_command ($options_ref, $cmd, $error_strings_ref) ){
        print "aaaarrrrrggghhhhhhhh\n";
        push @$error_strings_ref,
            "DB_DEBUG>$0:\n====> failed to drop database for user "
            . "oscar:\n$DBI::errstr";
        return 0;
    }
    print( "DB_DEBUG>$0:\n====> in oda::drop_database dropdb succeeded\n")
        if $$options_ref{debug} || $$options_ref{verbose};

    # since we successfully dropped the entire database,
    # reset the cache of table names and 
    # reset the cache of table/field names
    $cached_all_table_names_ref = undef;
    $cached_all_tables_fields_ref = undef;

    return 1;
}

    
#********************************************************************#
#********************************************************************#
#                                                                    #
# internal function to execute a shell command                       #
#                                                                    #
#********************************************************************#
#********************************************************************#
# inputs:  options            reference to options hash
#          error_strings_ref  optional reference to array for errors
#
# return: non-zero if success


sub do_shell_command {
    my ($options_ref, $command, $error_strings_ref) = @_;
    print "DB_DEBUG>$0:\n====> executing shell command <$command>\n"
        if $$options_ref{verbose};
    if (!system($command)) {
        print "DB_DEBUG>$0:\n====> <$command> succeeded\n" 
            if $$options_ref{debug};
        return 1;
    } else {
        print "DB_DEBUG>$0:\n====> <$command> failed\n" 
            if $$options_ref{debug};
        return 0;
    }
}


#********************************************************************#
#********************************************************************#
#                                                                    #
# exported function to initialize the %locked_tables.                #
#                                                                    #
#********************************************************************#
#********************************************************************#
# initialize the locking process
#  - empty the %locked_tables
#  - copy $temp_cached_all_tables_fields to $cached_all_tables_fields_ref
#  - and then set $temp_cached_all_tables_fields to be "undef"

sub initialize_locked_tables{
    %locked_tables = ();
    $cached_all_tables_fields_ref = $temp_cached_all_tables_fields;
    $temp_cached_all_tables_fields = undef;
}
    

#********************************************************************#
#********************************************************************#
#                                                                    #
# internal function to check to see if root password is setup        #
#                                                                    #
#********************************************************************#
#********************************************************************#
# Use the global variable %options.
#
# return: non-zero if success
#         nothing of %options is changed returning 0 if fails.

sub check_root_password{

    my @fake_root_passwords = ("foo","bogus");
    my $root_pass = "";
    my $simple_check_cmd = "";
    foreach $root_pass (@fake_root_passwords){
        $simple_check_cmd = "PGPASSWORD='$root_pass' psql -U postgres -l";
        system("$simple_check_cmd > /dev/null 2>&1");
        if ($?){
            $AUTH = 1;
            last;
        }
    }

    if (!$AUTH){
        print "DB_DEBUG>$):\n====> $database admin(postgres) password is not set.\n"
            if $options{debug};
        return 0;
    } else {    
        $options{password} = "";
        $options{user} = "";
        print "\n================================================================\n";
        print "Your $database has already setup the admin(postgres) password.\n";
        my $password = "";
        while (1) {
            print "To proceed, please enter your admin(postgres) password of $database: ";
            $| = 1;
            system("stty -echo");
            chomp($password = <STDIN>);
            print "\n";
            system("stty echo");
            $simple_check_cmd = "PGPASSWORD='$password' psql -U postgres -l";
            system("$simple_check_cmd > /dev/null 2>&1");
            last if( !$? );

            print "\nThe password is not correct!!! Please try it again.\n";
        }

        # Set "postgres" to the user and the user's input to the password of %options
        $options{user} = "postgres";
        $options{password} = $password;
        print "================================================================\n\n";
    }
    print "The postgres password : $options{password}\n" if $options{debug};
    return 1; 
}


1;
