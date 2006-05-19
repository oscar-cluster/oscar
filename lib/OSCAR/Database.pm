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
#
# Copyright (c) 2005-2006 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# Copyright (c) 2005 Bernard Li <bli@bcgsc.ca>
#
# Copyright (c) 2006 Erich Focht <efocht@hpce.nec.com>
#

#
# $Id$
#

# This is a new version of ODA

# Database.pm, located at the next level of the ODA hierarchy, is an
# abstract Perl module to handle directly all the database operations
# under the control of oda.pm. Many Perl subroutines defined at
# Database.pm are exported so that non-database codes of OSCAR can use
# its subroutines as if they are defined by importing Database.pm


# Most frequently used internal subroutines
# - do_select
# - do_update
# - do_insert


# Frequently used External subroutines
# - insert_into_table
# - delete_table
# - update_table
# - select_table


use strict;
use lib "$ENV{OSCAR_HOME}/lib","/usr/lib/perl5/site_perl";
use Carp;
use vars qw(@EXPORT $VERSION);
use base qw(Exporter);
use OSCAR::PackagePath;
use OSCAR::oda;

# oda may or may not be installed and initialized
my $oda_available = 0;
my %options = ();
my @error_strings = ();
my $options_ref = \%options;
my $database_connected = 0;
my $CLUSTER_NAME = "oscar";
my $DEFAULT = "Default";

$options{debug} = 1 
    if (exists $ENV{OSCAR_VERBOSE} && $ENV{OSCAR_VERBOSE} == 10)
        || $ENV{OSCAR_DB_DEBUG};

@EXPORT = qw( database_connect 
              database_disconnect 
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
              create_table
              insert_into_table
              update_table
              select_table
              delete_table

              delete_package
              delete_node
              delete_group_packages
              delete_groups
              do_select
              get_client_nodes
              get_client_nodes_info
              get_cluster_info_with_name
              get_gateway
              get_group_packages_with_groupname
              get_groups
              get_groups_for_packages
              get_headnode_iface
              get_image_info_with_name
              get_install_mode
              get_installable_packages
              get_networks
              get_nics_info_with_node
              get_nics_with_name_node
              get_node_info_with_name
              get_node_package_status_with_group_node
              get_node_package_status_with_node
              get_package_info_with_name
              get_packages
              get_packages_related_with_package
              get_packages_related_with_name
              get_packages_switcher
              get_packages_servicelists
              get_packages_with_class
              get_selected_group
              get_selected_group_packages
              get_unselected_group_packages
              insert_packages
              insert_pkg_rpmlist
              is_installed_on_node
	          list_installable_packages
              link_node_nic_to_network
    	      list_selected_packages
    	      pkgs_of_opkg
              set_all_groups
              set_group_packages
              set_group_nodes
              set_groups
              set_groups_selected
              set_images
              set_image_packages
              set_install_mode
              set_nics_with_node
              set_node_with_group
              set_status
              update_node
              update_node_package_status
              update_packages

              dec_already_locked
              locking
              unlock
              single_dec_locked
	      );

######################################################################
#
#       Database Connection subroutines
#
######################################################################

#
# Connect to the oscar database if the oda package has been
# installed and the oscar database has been initialized.
# This function is not needed before executing any ODA 
# database functions, since they automatically connect to 
# the database if needed, but it is more effecient to call this
# function at the start of your program and leave the database
# connected throughout the execution of your program.
#
# inputs:   errors_ref   if defined and a list reference,
#                          put error messages into the list;
#                          if defined and a non-zero scalar,
#                          print out error messages on STDERR
#           options        options reference to oda options hash
# outputs:  status         non-zero if success

sub database_connect {
    my ( $passed_options_ref, 
         $passed_errors_ref ) = @_;


    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ( $options_ref, $error_strings_ref ) = fake_missing_parameters
    ( $passed_options_ref, $passed_errors_ref );        

    if ( $$options_ref{debug} ) {
    my ($package, $filename, $line) = caller;
        print "DB_DEBUG>$0:\n====> in Database\:\:connect called from package=$package $filename\:$line\n";
    }

    # if the database is not already available, ...
    if ( ! $database_connected ) {

        # if oda was not installed the last time that 
        # this was called, try to load in the module again
        if ( ! $oda_available ) {
            eval "use OSCAR::oda";
            $oda_available = ! $@;
            carp("in database_connect cannot use oda: $@") if ! $oda_available;
        }
        print "DB_DEBUG>$0:\n====> in Database::database_connect now oda_available=$oda_available\n" 
            if $$options_ref{debug};
        
        # assuming oda is available now, ...
        if ( $oda_available ) {

            # try to connect to the database
            if ( oda::oda_connect( $options_ref,
                       $error_strings_ref ) ) {
            print "DB_DEBUG>$0:\n====> in Database::database_connect connect worked\n" if $$options_ref{debug};
            $database_connected = 1;
            }
            print_error_strings($error_strings_ref);
        }
    }

    print "DB_DEBUG>$0:\n====> in Database::database_connect returning database_connected=$database_connected\n" 
    if $$options_ref{debug};
    return $database_connected;
}

#
# Disconnect database connection. This is done through the
# oda_disconnect in OSCAR::oda.pm
#
# inputs:   errors_ref   if defined and a list reference,
#                          put error messages into the list;
#                          if defined and a non-zero scalar,
#                          print out error messages on STDERR
#           options        options reference to oda options hash
# outputs:  status         non-zero if success

sub database_disconnect {
    my ( $passed_options_ref, 
         $passed_errors_ref ) = @_;
     
    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ( $options_ref, $error_strings_ref ) = fake_missing_parameters
    ( $passed_options_ref, $passed_errors_ref );        

    if ( $$options_ref{debug} ) {
    my ($package, $filename, $line) = caller;
        print "DB_DEBUG>$0:\n====> in Database\:\:disconnect called from package=$package $filename\:$line\n";
    }

    # if the database is not connected, done
    return 1 if ! $database_connected;

    # disconnect from the database
    oda::oda_disconnect( $options_ref, $error_strings_ref );
    $database_connected = 0;

    print_error_strings($error_strings_ref);

    return 1;
}

######################################################################
#
#           Most frequently used
#       Internal database subroutines
#
######################################################################

######################################################
# Three main query subroutines
#
#   - do_select
#   - do_insert
#   - do_update
#
# These subroutines directly call the oda query command
# if query succeeds, return 1. Otherwise, return 0
########################################################## 

sub do_select {
    my ($sql,
        $result_ref,
        $options_ref,
        $error_strings_ref) = @_;

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::do_select SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug} || $$options_ref{verbose};
    push @$error_strings_ref, $debug_msg;

    my $error_msg = "Failed to query for << $sql >>";
    push @$error_strings_ref, $error_msg;
    my $success = oda::do_query($options_ref,
            $sql,
            $result_ref,
            $error_strings_ref);
    
    $error_strings_ref = \@error_strings;
    return  $success;
}

sub do_insert {
    my ($sql, $table,$options_ref,$error_strings_ref) = @_;

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::do_insert SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $success = oda::do_sql_command($options_ref,
            $sql,
            "INSERT Table into $table",
            "Failed to insert values into $table table",
            $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return  $success;
}            

sub do_update {
    my ($sql, $table,$options_ref,$error_strings_ref) = @_;

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::do_update SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $success = oda::do_sql_command($options_ref,
            $sql,
            "UDATE Table $table",
            "Failed to update $table table",
            $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return  $success;
}            

######################################################################
#
#           Most frequently used 
#       External database subroutines
#
######################################################################


sub insert_into_table {
    my ($options_ref,$table,$field_value_ref,$error_strings_ref) = @_;
    my $sql = "INSERT INTO $table ( ";
    my $sql_values = " VALUES ( ";
    
    my $flag = 0;
    my $comma = "";
    while ( my($field, $value) = each %$field_value_ref ){
        $comma = ", " if $flag;
        $sql .= "$comma $field";
        $flag = 1;
        $value = ($value eq "NOW()"?$value:"'$value'");
        $sql_values .= "$comma $value";
    }    
    $sql .= ") $sql_values )";
    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::insert_into_table SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $error_msg = "Failed to insert values to $table table";
    my $success = oda::do_sql_command($options_ref,
            $sql,
            "Insert Table $table",
            $error_msg,
            $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return  $success;
}

sub delete_table {
    my ($options_ref,$table,$where,$error_strings_ref) = @_;
    my $sql = "DELETE FROM $table ";
    $where = $where?$where:"";
    $sql .= " $where ";

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::delete_table SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $error_msg = "Failed to delete values from $table table";
    my $success = oda::do_sql_command($options_ref,
            $sql,
            "DELETE Table $table",
            $error_msg,
            $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return  $success;
}



sub update_table {
    my ($options_ref,$table,$field_value_ref,$where,$error_strings_ref) = @_;
    my $sql = "UPDATE $table SET ";
    my $flag = 0;
    my $comma = "";
    while ( my($field, $value) = each %$field_value_ref ){
        $comma = ", " if $flag;
        $value = ($value eq "NOW()"?$value:"'$value'");
        $sql .= "$comma $field=$value";
        $flag = 1;
    }
    $where = $where?$where:"";
    $sql .= " $where ";
    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::update_table SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;
    my $error_msg = "Failed to update values to $table table";
    my $success = oda::do_sql_command($options_ref,
            $sql,
            "UPDATE Table $table",
            $error_msg,
            $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return  $success;
}

sub select_table {
    my ($options_ref,$table,$field_ref,$where,$result,$error_strings_ref) = @_;
    my $sql = "SELECT ";
    my $flag = 0;
    my $comma = "";
    foreach my $field (@$field_ref){
        $comma = ", " if $flag;
        $sql .= "$comma $field";
        $flag = 1;
    }
    $where = $where?$where:"";
    if(ref($where) eq "HASH"){
        $flag = 0;
        my $and = "";
        my $where_str = " WHERE ";
        while (my ($key, $value) = each %$where){
            $and = "AND " if $flag;
            $where_str .= "$and $key='$value' ";
            $flag = 1;
        }
        $where = $where_str;
    }
    $sql .= " FROM $table $where ";
    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::select_table SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $error_msg = "Failed to query values from $table table";
    push @$error_strings_ref, $error_msg;
    my $success = oda::do_query($options_ref,
            $sql,
            $result,
            $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return  $success;
}

sub create_table {
     my ($options_ref, $error_strings_ref) = @_;
        
    my $sql_dir = "$ENV{OSCAR_HOME}/packages/oda/scripts";
    my $sql_file = "$sql_dir/oscar_table.sql";
    
    print "DB_DEBUG>$0:\n====> in Database::create_table uses the SQL statement which are already defined at $sql_file" if $$options_ref{verbose};
    my $cmd = "mysql -u root oscar < $sql_file";

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::create_table runs the command : $cmd\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $success = oda::do_shell_command($options_ref, "$cmd", $error_strings_ref);

    $error_strings_ref = \@error_strings;
    return  $success;
}    




# Uses the hostname command to match against the node names in the
# database, returning the matching name. Takes into account domain
# names being tacked onto the hostname output and/or the node names.
# Does not use the "nodes" shortcut, in case it is called early.
# Returns the matching node name, returns undefined if cannot find.
#
# paramaters are: errors_ref  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_find_node_name {
    
    my ( $passed_errors_ref ) = @_;
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;

    # find the hostname of this machine
    my $hostname = `hostname 2>/dev/null`;
    chomp $hostname;
    my @hostname_fields = split( ' ', $hostname );
    if ( scalar @hostname_fields != 1 ) {
    push @$error_strings_ref,
    "DB_DEBUG>$0:\n====> in database_find_node_name hostname command returned unknown output <$hostname>";
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
        warn shift @$error_strings_ref while @$error_strings_ref;
    }
    return undef;
    }

    return database_hostname_to_node_name( $hostname,
                       $passed_errors_ref );
}

# Searches the database nodes table for a record matching
# a given hostname. Takes into account domain names being 
# tacked onto the hostname output and/or the node names.
# Does not use the "nodes" shortcut, in case it is called early.
# Returns the matching node name, returns undefined if cannot find.
#
# paramaters are: hostname      hostname string
#           passed_errors_ref if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_hostname_to_node_name {
    
    my ( $hostname, 
     $passed_errors_ref ) = @_;
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;

    # find the name, domain, and hostname field values for all
    # of the nodes table records in the database
    my @requested_fields = qw( hostname domain );
    my $sql = "SELECT * FROM Nodes";
    my @node_records = ();
    my $node_records_ref = \@node_records;
    oda::do_query($options_ref,
                $sql,
                $node_records_ref,
                $passed_errors_ref );
    return undef if ! defined $node_records_ref;
    if ( ! @$node_records_ref ) {
    push @$error_strings_ref,
    "DB_DEBUG>$0:\n====> in database_find_node_name cannot find any node names in database";
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
        warn shift @$error_strings_ref while @$error_strings_ref;
    }
    return undef;
    }

    # loop through the node records ...
    foreach my $node_ref ( @$node_records_ref ) {
    my $node_name = $$node_ref{name};
    return $node_name;
    return $node_name
        if defined $$node_ref{ hostname } &&
        $hostname eq $$node_ref{ hostname };
    # match the given hostname to the name field
    return $hostname
        if $hostname eq $node_name;
    # if the given hostname includes a domain, ...
    if ( $hostname =~ /\./ ) {
        # find the given hostname without the domain
        my @hostname_fields = split( '.', $hostname );
        my $hostname_without_domain = $hostname_fields[0];
        # match the domain-less given hostname to
        # the record hostname field
        return $hostname_without_domain 
        if exists $$node_ref{ hostname } &&
        $hostname_without_domain eq 
        $$node_ref{ hostname };
        # match the domain-less given hostname to
        # the record name field
        return $hostname_without_domain 
        if $hostname_without_domain eq $node_name;
    }
    # if the record hostname field includes a domain, ...
    if ( exists $$node_ref{ hostname } &&
         $$node_ref{ hostname } =~ /\./ ) {
        # find the hostname field without the domain
        my @hostname_fields = 
        split( '.', $$node_ref{ hostname } );
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
#           passed_errors_ref if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR
#                 verbose       if defined and non-zero, verbose output
#                 debug         if defined and non-zero, debug output

sub database_program_variable_get {
    
    my ( $program,
     $variable,
     $passed_errors_ref ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
    OSCAR::Database::database_connect( undef, $passed_errors_ref ) ||
        return undef;

    # do the database read for all of the variable values
    # for the specified program and variable, returning
    # undefined if any errors
    my @tables_fields = qw( program_variable_values
                program_variable_values.value );
    my @wheres = ( "program_variable_values.program=$program",
           "program_variable_values.variable=$variable" );
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my @records = ();
    if ( ! oda::read_records( $options_ref,
                  \@tables_fields,
                  \@wheres,
                  \@records,
                  1,
                  $error_strings_ref ) ) {
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
#           passed_errors_ref if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_program_variable_put {
    
    my ( $program,
     $variable,
     $values_ref,
     $passed_errors_ref ) = @_;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
    OSCAR::Database::database_connect( undef, $passed_errors_ref ) ||
    return undef;
    my $status = 1;

    # remove all the previous values for this variable
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my @command_results = ();
    if ( ! oda::execute_command( $options_ref,
                 "remove_program_variable $program $variable",
                 \@command_results,
                 $error_strings_ref ) ) {
    push @$error_strings_ref,
    "cannot remove old values for program $program variable $variable from the ODA database";
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
#           passed_errors_ref if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_program_variables_get {
    
    my ( $program,
     $passed_errors_ref ) = @_;

    # do the database read for all of the variable names
    # and values for the specified program, returning
    # undefined if any errors
    my @tables_fields = qw( program_variable_values
                program_variable_values.variable
                program_variable_values.value );
    my @wheres = ( "program_variable_values.program=$program" );
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my @records = ();
    if ( ! oda::read_records( $options_ref,
                  \@tables_fields,
                  \@wheres,
                  \@records,
                  1,
                  $error_strings_ref ) ) {
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
        warn shift @$error_strings_ref while @$error_strings_ref;
    }
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
#           passed_errors_ref if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

sub database_program_variables_put {
    
    my ( $program,
     $variables_ref,
     $passed_errors_ref ) = @_;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
    OSCAR::Database::database_connect( undef, $passed_errors_ref ) ||
        return ( undef, undef, undef );
    my $status = 1;

    # remove all the previous variables for this program
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my @command_results = ();
    if ( ! oda::execute_command( $options_ref,
                 "remove_program_variables $program",
                 \@command_results,
                 $error_strings_ref ) ) {
    push @$error_strings_ref,
    "cannot remove old variables for program $program from the ODA database";
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
        if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
            warn shift @$error_strings_ref while @$error_strings_ref;
        }
        $status = 0;
        }
    }
    }

    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
# parameters are: errors_ref  if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR
#
# returned values:  architecture
#                   distribution
#                   distribution_version

sub database_read_filtering_information {
    
    my ( $passed_errors_ref ) = @_;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
    OSCAR::Database::database_connect( undef, $passed_errors_ref ) ||
        return ( undef, undef, undef );

    # read them all in

    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;

    my $architecture = undef;
    my $distribution = undef;
    my $distribution_version = undef;
    my @fields = 
        ("server_architecture", "server_distribution", "server_distribution_version");
    my $where = " WHERE name='$CLUSTER_NAME' ";
    my @results = ();
    if ( ! select_table (\%options,"Clusters", \@fields, $where, \@results, \@error_strings ) ){
        push @$error_strings_ref,
            "Error reading the architecture, server distribution, ".
            "and server distribution version from the database";
    } elsif ( ! @results ) {
        push @$error_strings_ref,
        "No results returned reading the architecture, server distribution, " .
        "and server distribution version from the database";
    } else {
        foreach my $results_ref (@results){ 
            $architecture = $$results_ref{server_architecture};
            $distribution = $$results_ref{server_distribution};
            $distribution_version = $$results_ref{server_distribution_version};
        }
    }


    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
#           passed_errors_ref if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR

# DongInn Kim 
# This subroutine can be deleted because it is not used any more.
sub database_read_table_fields {
    
    my ( $table,
     $requested_fields_ref,
     $wheres_ref,
     $passed_key_name,
     $passed_errors_ref ) = @_;

    # if they didn't specify an index field name, use "name"
    my $key_name = ( defined $passed_key_name ) ? $passed_key_name : "name";

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
    OSCAR::Database::database_connect( undef, $passed_errors_ref ) ||
        return undef;
    print "DB_DEBUG>$0:\n====> in Database::database_read_table_fields entering database_read_table_fields table=$table key=$key_name\n"
    if $$options_ref{debug};

    # get a list of field names for this database table

    my %fields_in_table = ();
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    if ( ! oda::list_fields( $options_ref,
                 $table,
                 \%fields_in_table,
                 $error_strings_ref ) ) {
    push @$error_strings_ref,
    "cannot read the field names for database table <$table> from the ODA database";
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
#   passed_errors_ref   if defined and a list reference,
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
     $passed_errors_ref ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
    OSCAR::Database::database_connect( undef, $passed_errors_ref ) ||
        return undef;

    # execute the command
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my @command_results = ();
    my $success = oda::execute_command( $options_ref,
                    $command_args_ref,
                    \@command_results,
                    $error_strings_ref );
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
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
#           passed_errors_ref   if defined and a list reference,
#                               put error messages into the list;
#                               if defined and a non-zero scalar,
#                               print out error messages on STDERR
#
# returns a list of rpm names, or undef if an error

sub database_rpmlist_for_package_and_group {
    
    my ( $package,
     $package_ver,
     $group,
     $passed_errors_ref ) = @_;

    #my ($calling_package, $calling_filename, $line) = caller;

    # since we are going to do a number of database operations, we'll
    # try to be more effecient by connecting to the database first if
    # we weren't connected when called, then perform the operations, 
    # then disconnect if we weren't connected when we were called.

    ( my $was_connected_flag = $database_connected ) ||
    OSCAR::Database::database_connect( undef, $passed_errors_ref ) ||
        return undef;

    # read in all the packages_rpmlists records for this package
    my @packages_rpmlists_records = ();
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my $number_of_records = 0;
    # START LOCKING FOR NEST
    my %options = ();
    my @tables = ("Packages_rpmlists", "Packages");
#    locking("read", \%options, \@tables, $error_strings_ref);
    my $sql = "SELECT Packages_rpmlists.* FROM Packages_rpmlists, Packages " .
              "WHERE Packages.id=Packages_rpmlists.package_id " .
              "AND Packages.package='$package' " .
              ($package_ver?"AND Packages.version='$package_ver'":"");
    my $success = 
        oda::do_query( $options_ref,
                    $sql,
                    \@packages_rpmlists_records,
                    \$error_strings_ref);
    # UNLOCKING FOR NEST
#    unlock(\%options, $error_strings_ref);
    if ( ! $success ) {
    push @$error_strings_ref,
    "Error reading packages_rpmlists records for package $package";
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
        warn shift @$error_strings_ref while @$error_strings_ref;
    }
        OSCAR::Database::database_disconnect() if ! $was_connected_flag;
     return undef;
    }

    # read in the oscar global architecture, distribution, etc
    my ( $architecture,
     $distribution,
     $distribution_version ) =
         database_read_filtering_information( $passed_errors_ref );
    
    # now build the matches list
    my @rpms = ();
    foreach my $record_ref ( @packages_rpmlists_records ) {
    #print "record_ref{group_name} : $$record_ref{group_name}\n";
    #print "group : $group\n";
        if (
            ( ! defined $$record_ref{group_arch} ||
              $$record_ref{group_arch} eq "all" ||
              ! defined $architecture ||
              $$record_ref{group_arch} eq $architecture )
            &&
            ( ! defined $$record_ref{distro} ||
              $$record_ref{distro} eq "all" ||
              ! defined $distribution ||
              $$record_ref{distro} eq $distribution )
            &&
            ( ! defined $$record_ref{distro_version} ||
              $$record_ref{distro_version} eq "all" ||
              ! defined $distribution_version ||
              $$record_ref{distro_version} eq $distribution_version )
            &&
            ( ! defined $$record_ref{group_name} ||
              $$record_ref{group_name} eq "all" ||
              ! defined $group ||
              $$record_ref{group_name} eq $group )
            ) { push @rpms, $$record_ref{rpm}; }
    }
        
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return @rpms;
}

#########################################################################
#  Subroutine: list_selected_packages                                   #
#  Parameters: The "type" of packages - "core", "noncore", or "all"     #
#  Returns   : A list of packages selected for installation.            #
#  If you do not specify the "type" of packages, "all" is assumed.      #
#                                                                       #
#  Usage: @packages_that_are_selected = list_selected_packages();       #
#
# EF: moved here from Package.pm                                        #
#########################################################################
sub list_selected_packages # ($type[,$sel_group]) -> @selectedlist
{
    my ($type,$sel_group) = @_; #shift;

    # If no argument was specified, use "all"

    $type = "all" if ((!(defined $type)) || (!$type));

    # make the database command and do the database read

    # get the selected group.
    $sel_group = &get_selected_group() if ! $sel_group;

    
    my $command_args = "SELECT Packages.package, Packages.version " .
             "FROM Packages, Group_Packages " .
             "WHERE Packages.id=Group_Packages.package_id ".
             "AND Group_Packages.group_name='$sel_group' ".
             "AND Group_Packages.selected=1";
    if ($type eq "all"){
        $command_args = $command_args;
    }elsif ($type eq "core"){
        $command_args .= " AND Packages.__class='core' ";
    } else {
        $command_args .= " AND Packages.__class!='core' ";
    }

    my @packages = ();
    my @tables = ("Packages", "Group_Packages", "Nodes", "Node_Package_Status");
    print "DB_DEBUG>$0:\n====> in Database::list_selected_packages SQL: $command_args\n"
        if $options{debug};
    if ( OSCAR::Database::single_dec_locked( $command_args,
                                                   "READ",
                                                   \@tables,
                                                   \@packages,
                                                   undef) ) {
        return @packages;
    } else {
    warn "Cannot read selected packages list from the ODA database.";
    return undef;
    }
}



#
# Simplify database_rpmlist_for_package_and_group
# Usage:
#    pkgs_of_opkg($opkg, $opkg_ver, \@errors, 
#                 chroot    => $image_path,
#                 arch      => $architecture,
#                 distro    => $compat_distro_name,
#                 distro_ver=> $compat_distrover,
#                 group     => $host_group,
#                 os        => $os_detect_object );
# The selection arguments "group", "chroot" and "os" can be omitted.
# "os" should be a reference to a hash array returned by OS_Detect.
# "chroot" is a path which will be OS_Detect-ed,
# "arch", "distro", "distro_ver" specify the targetted architecture,
#     distro, etc... For ia32 the "arch" should i386 (uname -i). The
#     distro name corresponds to the compat_distro names in OS_Detect! So
#     use rhel, fc, mdk, etc...
# "group" is a host group name like oscar_server
#

sub pkgs_of_opkg {
    
    my ( $opkg,
     $opkg_ver,
     $passed_errors_ref,
     %sel ) = @_;

    #my ($calling_package, $calling_filename, $line) = caller;

    my ($chroot,$group,$os);
    my ($architecture, $distribution, $distribution_version);
    if (exists($sel{arch}) && exists($sel{distro}) &&
	     exists($sel{distro_ver})) {
	$architecture = $sel{arch};
	$distribution = $sel{distro};
	$distribution_version = $sel{distro_ver};

    } else {
	if (!exists($sel{os})) {
	    if (exists($sel{chroot})) {
		$chroot = $sel{chroot};
	    } else {
		$chroot = "/";
	    }
	    $os = distro_detect_or_die($chroot);
	}
	$architecture = $os->{arch};
	$distribution = $os->{compat_distro};
	$distribution_version = $os->{compat_distrover};
    }
    if (exists($sel{group})) {
	$group = $sel{group};
    }


    ( my $was_connected_flag = $database_connected ) ||
	OSCAR::Database::database_connect(undef, $passed_errors_ref ) ||
        return undef;

    # read in all the packages_rpmlists records for this opkg
    my @packages_rpmlists_records = ();
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
			      ref($passed_errors_ref) eq "ARRAY" ) ?
			      $passed_errors_ref : \@error_strings;
    my $number_of_records = 0;
    # START LOCKING FOR NEST
    my %options = ();
    my @tables = ("Packages_rpmlists", "Packages");
#    locking("read", \%options, \@tables, $error_strings_ref);
    my $sql = "SELECT Packages_rpmlists.* FROM Packages_rpmlists, Packages " .
              "WHERE Packages.id=Packages_rpmlists.package_id " .
              "AND Packages.package='$opkg' " .
              ($opkg_ver?"AND Packages.version='$opkg_ver'":"");
    my $success = 
        oda::do_query( $options_ref,
                    $sql,
                    \@packages_rpmlists_records,
                    \$error_strings_ref);
    # UNLOCKING FOR NEST
#    unlock(\%options, $error_strings_ref);
    if ( ! $success ) {
	push @$error_strings_ref,
	"Error reading packages_rpmlists records for opkg $opkg";
	if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
	    warn shift @$error_strings_ref while @$error_strings_ref;
	}
	OSCAR::Database::database_disconnect() if ! $was_connected_flag;
	return undef;
    }

    # now build the matches list
    my @pkgs = ();
    foreach my $record_ref ( @packages_rpmlists_records ) {
        if (
            ( ! defined $$record_ref{group_arch} ||
              $$record_ref{group_arch} eq "all" ||
              ! defined $architecture ||
              $$record_ref{group_arch} eq $architecture )
            &&
            ( ! defined $$record_ref{distro} ||
              $$record_ref{distro} eq "all" ||
              ! defined $distribution ||
              $$record_ref{distro} eq $distribution )
            &&
            ( ! defined $$record_ref{distro_version} ||
              $$record_ref{distro_version} eq "all" ||
              ! defined $distribution_version ||
              $$record_ref{distro_version} eq $distribution_version )
            &&
            ( ! defined $$record_ref{group_name} ||
              $$record_ref{group_name} eq "all" ||
              ! defined $group ||
              $$record_ref{group_name} eq $group )
            ) { push @pkgs, $$record_ref{rpm}; }
    }
        
    OSCAR::Database::database_disconnect() if ! $was_connected_flag;

    return @pkgs;
}

######################################################################
#
#       Select SQL query: database subroutines
#
######################################################################


sub get_node_info_with_name {
    my ($node_name,
        $options_ref,
        $error_strings_ref) = @_;
    my @results = ();
    my $sql = "SELECT * FROM Nodes WHERE name='$node_name'";
    print "DB_DEBUG>$0:\n====> in Database::get_node_info_with_name SQL : $sql\n" if $$options_ref{debug};
    if(do_select($sql,\@results, $options_ref, $error_strings_ref)){
        my $node_ref = pop @results;
        return $node_ref;
    }else{
        undef;
    }
}

sub get_client_nodes {
    my ($results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT Nodes.* FROM Nodes, Groups ".
            "WHERE Groups.id=Nodes.group_id ".
            "AND Groups.name='oscar_clients'";
    print "DB_DEBUG>$0:\n====> in Database::get_client_nodes SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref, $options_ref, $error_strings_ref);
}

sub get_node_info {
    my ($results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Nodes";
    print "DB_DEBUG>$0:\n====> in Database::get_node_info SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref, $options_ref, $error_strings_ref);
}

sub get_client_nodes_info {
    my ($server,
        $results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Nodes WHERE name!='$server'";
    print "DB_DEBUG>$0:\n====> in Database::get_client_nodes_info SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref, $options_ref, $error_strings_ref);
}

sub get_nodes {
    my ($options_ref,
        $error_strings_ref) = @_;
    my @results = ();
    get_node_info(\@results,$options_ref, $error_strings_ref);
    my @list_of_nodes = ();
    foreach my $results_ref (@results){
        push @list_of_nodes, $$results_ref{name};
    }
    return @list_of_nodes;
}

sub get_networks {
    my ($results,
        $options_ref,
        $error_strings_ref)= @_;
    my $sql ="SELECT * FROM Networks ";
    print "DB_DEBUG>$0:\n====> in Database::get_networks SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_nics_info_with_node {
    my ($node,
        $results,
        $options_ref,
        $error_strings_ref)= @_;
    my $sql ="SELECT Nics.* FROM Nics, Nodes ".
             "WHERE Nodes.id=Nics.node_id AND Nodes.name='$node'";
    print "DB_DEBUG>$0:\n====> in Database::get_nics_info_with_node SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_nics_with_name_node {
    my ($nic,
        $node,
        $results,
        $options_ref,
        $error_strings_ref)= @_;
    my $sql ="SELECT Nics.* FROM Nics, Nodes ".
             "WHERE Nodes.id=Nics.node_id AND Nodes.name='$node' " .
             "AND Nics.name='$nic'";
    print "DB_DEBUG>$0:\n====> in Database::get_nics_with_name_node SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_cluster_info_with_name {
    my ($cluster_name,
        $options_ref,
        $error_strings_ref) = @_;
    my @results = ();
    my $where = ($cluster_name?"'$cluster_name'":"'oscar'");
    my $sql = "SELECT * FROM Clusters WHERE name=$where";
    print "DB_DEBUG>$0:\n====> in Database::get_cluster_info_with_name SQL : $sql\n" if $$options_ref{debug};
    do_select($sql,\@results, $options_ref, $error_strings_ref);
    if(@results){
        return ((scalar @results)==1?(pop @results):@results);
    }else{
        undef;
    }
}

sub get_package_info_with_name {
    my ($package_name,
        $options_ref,
        $error_strings_ref,
        $version) = @_;
    my @results = ();
    my $sql = "SELECT * FROM Packages WHERE package='$package_name' ";
    if( $version ){
        $sql .= "AND version='$version'";
    }
    print "DB_DEBUG>$0:\n====> in Database::get_package_info_with_name SQL : $sql\n" if $$options_ref{debug};
    if(do_select($sql,\@results, $options_ref, $error_strings_ref)){
        my $package_ref = pop @results;
        return $package_ref;
    }else{
        undef;
    }
}

sub get_package_info {
    my ($options_ref,
        $error_strings_ref,
        $field_ref) = @_;
    my @results = ();
    my $sql = "SELECT";
    if(defined $field_ref){
        my $flag = 0;
        my $comma = "";
        foreach my $field (@$field_ref){
            $comma = "," if $flag;
            $sql .= "$comma $field";
            $flag = 1;
        }    
    } else {
        $sql .= " * ";
    }   
    $sql .= " FROM Packages";
    print "DB_DEBUG>$0:\n====> in Database::get_package_info SQL : $sql\n" if $$options_ref{debug};
    if(do_select($sql,\@results, $options_ref, $error_strings_ref)){
        return \@results;
    }else{
        undef;
    }
}

sub get_packages {
    my ($options_ref,
        $error_strings_ref) = @_;
    my $results = get_package_info($options_ref, $error_strings_ref);
    my @list_of_packages = ();
    foreach my $results_ref (@$results){
        push @list_of_packages, $$results_ref{package};
    }
    return @list_of_packages;
}

sub get_packages_with_class {
    my ($class,
        $results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT id, package, version FROM Packages ".
              "WHERE __class='$class' ";
    print "DB_DEBUG>$0:\n====> in Database::get_packages_with_class SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref,$options_ref,$error_strings_ref);
}

sub get_fields {
    my ($options_ref,
        $table,
        $error_strings_ref) = @_;
    my %fields = ();    
    oda::list_fields($options_ref, $table, \%fields, $error_strings_ref);
    my @list_of_fields = ();
    foreach my $field (sort keys %fields){
        push @list_of_fields, $field;
    }
    return @list_of_fields;
}


# These two subroutines(get_packages_related_with_package and
# get_packages_related_with_name) take care of 
# Packages_conflicts, Packages_provides, and Packages_requires
# tables.
sub get_packages_related_with_package {
    my ($part_name,
        $package,
        $results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT P.package, P.id, S.p2_name, S.type " .
              "FROM Packages P, Packages_$part_name S " .
              "WHERE P.id=S.p1_id ".
              "AND P.package='$package'";  
    print "DB_DEBUG>$0:\n====> in Database::get_packages_related_with_package SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref,$options_ref,$error_strings_ref);
}    

sub get_packages_related_with_name {
    my ($part_name,
        $name,
        $results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT P.package, P.id, S.p2_name, S.type " .
              "FROM Packages P, Packages_$part_name S " .
              "WHERE P.id=S.p1_id ".
              "AND S.p2_name='$name'";  
    print "DB_DEBUG>$0:\n====> in Database::get_packages_related_with_name SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref,$options_ref,$error_strings_ref);
}    


sub get_packages_switcher {
    my ($results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT P.package, S.switcher_tag, S.switcher_name " .
              "FROM Packages P, Packages_switcher S " .
              "WHERE P.id=S.package_id";
    print "DB_DEBUG>$0:\n====> in Database::get_packages_switcher SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref,$options_ref,$error_strings_ref);
}    

sub get_packages_servicelists {
    my ($results_ref,
        $group_name,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT distinct P.package, S.service " .
              "FROM Packages P, Packages_servicelists S, Node_Package_Status N, " .
              "Group_Nodes G " .
              "WHERE P.id=S.package_id AND N.package_id=S.package_id ".
              "AND G.node_id=N.node_id ";
    $sql .= ($group_name?" AND G.group_name='$group_name' AND S.group_name='$group_name'":" AND S.group_name!='oscar_server'");          
    print "DB_DEBUG>$0:\n====> in Database::get_packages_servicelists SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref,$options_ref,$error_strings_ref);
}    

sub get_selected_group {
    my ($options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT id, name From Groups " .
              "WHERE Groups.selected=1 ";
    my @results = ();
    print "DB_DEBUG>$0:\n====> in Database::get_selected_group SQL : $sql\n" if $$options_ref{debug};
    my $success = do_select($sql,\@results,$options_ref,$error_strings_ref);
    my $answer = undef;
    if ($success){
        my $ref = pop @results;
        $answer = $$ref{name};
    }
    return $answer;
}

sub get_selected_group_packages {
    my ($results_ref,
        $options_ref,
        $error_strings_ref,
        $group,
        $flag) = @_;
    $group = get_selected_group($options_ref,$error_strings_ref) if(!$group);    
    $flag = 1 if(! $flag);
    my $sql = "SELECT Packages.id, Packages.package, Packages.name, Packages.version " .
              "From Packages, Group_Packages, Groups " .
              "WHERE Packages.id=Group_Packages.package_id ".
              "AND Group_Packages.group_name=Groups.name ".
              "AND Groups.name='$group' ".
              "AND Groups.selected=1 ".
              "AND Group_Packages.selected=$flag";
    print "DB_DEBUG>$0:\n====> in Database::get_selected_group_packages SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref,$options_ref,$error_strings_ref);
}

sub get_unselected_group_packages {
    my ($results_ref,
        $options_ref,
        $error_strings_ref,
        $group) = @_;
    return get_selected_group_packages($results_ref,$options_ref,
                                       $error_strings_ref,$group,0);
}

sub get_group_packages_with_groupname {
    my ($group,
        $results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT Packages.id, Packages.package " .
              "From Packages, Group_Packages " .
              "WHERE Packages.id=Group_Packages.package_id ".
              "AND Group_Packages.group_name='$group'";
    print "DB_DEBUG>$0:\n====> in Database::get_group_packages_with_groupname SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref,$options_ref,$error_strings_ref);
}
    
sub get_node_package_status_with_group_node {
    my ($group,
        $node,
        $results,
        $options_ref,
        $error_strings_ref) = @_;
        my $sql = "SELECT Packages.package, Node_Package_Status.* " .
                 "From Packages, Group_Packages, Node_Package_Status, Nodes ".
                 "WHERE Packages.id=Group_Packages.package_id " .
                 "AND Group_Packages.group_name='$group' ".
                 "AND Node_Package_Status.package_id=Packages.id ".
                 "AND Node_Package_Status.node_id=Nodes.id ".
                 "AND Nodes.name='$node'";
    print "DB_DEBUG>$0:\n====> in Database::get_node_package_status_with_group_node SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_node_package_status_with_node {
    my ($node,
        $results,
        $options_ref,
        $error_strings_ref,
        $requested,
        $version) = @_;
        my $sql = "SELECT Packages.package, Node_Package_Status.* " .
                 "From Packages, Node_Package_Status, Nodes ".
                 "WHERE Node_Package_Status.package_id=Packages.id ".
                 "AND Node_Package_Status.node_id=Nodes.id ".
                 "AND Nodes.name='$node'";
        if (defined $requested && $requested ne "") {
            $sql .= " AND Node_Package_Status.requested=$requested ";
        }
        if (defined $version && $version ne "") {
            $sql .= " AND Packages.version=$version ";
        }
    print "DB_DEBUG>$0:\n====> in Database::get_node_package_status_with_node SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_node_package_status_with_node_package {
    my ($node,
        $package,
        $results,
        $options_ref,
        $error_strings_ref,
        $requested,
        $version) = @_;
        my $sql = "SELECT Packages.package, Node_Package_Status.* " .
                 "From Packages, Node_Package_Status, Nodes ".
                 "WHERE Node_Package_Status.package_id=Packages.id ".
                 "AND Node_Package_Status.node_id=Nodes.id ".
                 "AND Nodes.name='$node' AND Packages.package='$package'";
        if(defined $requested && $requested ne ""){
            $sql .= " AND Node_Package_Status.requested=$requested ";
        }
        if(defined $version && $version ne ""){
            $sql .= " AND Packages.version=$version ";
        }
    print "DB_DEBUG>$0:\n====> in Database::get_node_package_status_with_node_package SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_installable_packages {
    my ($results,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT Packages.id, Packages.package " .
              "FROM Packages, Group_Packages " .
              "WHERE Packages.id=Group_Packages.package_id ".
              "AND Group_Packages.group_name='Default'";
    print "DB_DEBUG>$0:\n====> in Database::get_installable_packages SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}


sub get_groups_for_packages {
    my ($results,
        $options_ref,
        $error_strings_ref,
        $group)= @_;
    my $sql ="SELECT distinct group_name FROM Group_Packages ";
    if(defined $group){ $sql .= "WHERE group_name='$group'"; }
    print "DB_DEBUG>$0:\n====> in Database::get_groups_for_packages SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_groups {
    my ($results,
        $options_ref,
        $error_strings_ref,
        $group)= @_;
    my $sql ="SELECT * FROM Groups ";
    if(defined $group){ $sql .= "WHERE name='$group'"; }
    print "DB_DEBUG>$0:\n====> in Database::get_groups SQL : $sql\n" if $$options_ref{debug};
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,$results, $options_ref, $error_strings_ref);
    return $$results[0] if $group;    
    return 0;
}

sub get_image_info_with_name {
    my ($image,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Images WHERE name='$image'";
    print "DB_DEBUG>$0:\n====> in Database::get_image_info_with_name SQL : $sql\n" if $$options_ref{debug};
    my @images = ();
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@images, $options_ref, $error_strings_ref);
    return (@images?pop @images:undef);
}

sub get_gateway {
    my ($node,
        $interface,
        $results,
        $options_ref,
        $error_strings_ref)= @_;
    my $sql ="SELECT Networks.gateway FROM Networks, Nics, Nodes ".
             "WHERE Nodes.id=Nics.node_id AND Nodes.name='$node'".
             "AND Networks.n_id=Nics.network_id AND Nics.name='$interface'";
    print "DB_DEBUG>$0:\n====> in Database::get_gateway SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

# This function returns the interface on the headnode that is on the same
# network as the compute nodes, typically = ./install_cluster <iface>
sub get_headnode_iface {
    my ($options_ref,
	$error_strings_ref) = @_;
    my $cluster_ref = get_cluster_info_with_name("oscar", $options_ref, $error_strings_ref);
    return $$cluster_ref{headnode_interface};
}

# Retrieve installation mode for cluster
sub get_install_mode {
    my ($options_ref,
        $error_strings_ref) = @_;
 
    my $cluster = "oscar";

    my $cluster_ref = get_cluster_info_with_name($cluster, $options_ref, $error_strings_ref);
    return $$cluster_ref{install_mode};
}


sub is_installed_on_node {
    my ($package_name,
        $node_name,
        $options_ref,
        $error_strings_ref,
        $version,
        $requested) = @_;
    my @result = ();    
    $requested = 8 if (!$requested);    
    my $sql = "SELECT Packages.package, Node_Package_Status.* " .
             "From Packages, Node_Package_Status, Nodes ".
             "WHERE Node_Package_Status.package_id=Packages.id ".
             "AND Node_Package_Status.node_id=Nodes.id ".
             "AND Packages.package='$package_name' ".
             "AND Nodes.name=";
    $sql .= ($node_name?"'$node_name'":"'oscar_server'"); 
    if(defined $requested && $requested ne ""){
        $sql .= " AND Node_Package_Status.requested=$requested ";
    }
    if(defined $version && $version ne ""){
        $sql .= " AND Packages.version=$version ";
    }
    print "DB_DEBUG>$0:\n====> in Database::is_installed_on_node SQL : $sql\n" if $$options_ref{debug};
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@result, $options_ref, $error_strings_ref);
    return (@result?1:0);    
}


#
# list_installable_packages - this returns a list of installable packages.
#
# You may specify "core", "noncore", or "all" as the first argument to
# get a list of core, noncore, or all packages (respectively).  If no
# argument is given, "all" is implied.
#
# EF: Moved here from Package.pm

sub list_installable_packages {
    my $type = shift;

    # If no argument was specified, use "all"

    $type = "all" if ((!(defined $type)) || (!$type));

    # make the database command and do the database read

    my $command_args;
    if ( $type eq "all" ) {
      $command_args = "packages_installable";
    } elsif ( $type eq "core" ) {
      $command_args = "packages_installable packages.class=core";
    } else {
      $command_args = "packages_installable packages.class!=core";
    }
    my @packages = ();
    my @tables = ("packages", "oda_shortcuts");
    print "DB_DEBUG>$0:\n====> in Database::list_installable_packages SQL : $command_args\n" if $$options_ref{debug};
    if ( OSCAR::Database::single_dec_locked( $command_args,
                                                    "READ",
                                                    \@tables,
                                                    \@packages,
                                                    undef) ) {
      return @packages;
    } else {
      warn "Cannot read installable packages list from the ODA database.";
      return undef;
    }
}


######################################################################
#
#       Delete/Insert/Update SQL query: database subroutines
#
######################################################################

sub delete_group_node {
    my ($node_id,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "DELETE FROM Group_Nodes WHERE node_id=$node_id";
    print "DB_DEBUG>$0:\n====> in Database::delete_group_node SQL : $sql\n" if $$options_ref{debug};
    return do_update($sql,"Group_Nodes", $options_ref, $error_strings_ref);
}

sub delete_group_packages {
    my ($group,
        $opkg,
        $options_ref,
        $error_strings_ref,
        $ver) = @_;

    my $package_ref = get_package_info_with_name($opkg,$options_ref,$error_strings_ref,$ver);
    my $package_id = $$package_ref{id};
    if($package_id){
        my $sql = "UPDATE Group_Packages SET selected=0 ".
            "WHERE group_name='$group' AND package_id=$package_id";
        print "DB_DEBUG>$0:\n====> in Database::delete_group_packages SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to delete values via << $sql >>"
            if! do_update($sql,"Group_Packages", $options_ref, $error_strings_ref);
        update_node_package_status(
              $options_ref,"oscar_server",$opkg,1,$error_strings_ref);
    }      
    return 1;    
}

sub delete_groups {
    my ($group,
        $options_ref,
        $error_strings_ref) = @_;
    my @results = ();
    get_groups(\@results,$options_ref,$error_strings_ref,$group);
    if(!@results){
        my $sql = "DELETE FROM Groups WHERE name='$group'";
        print "DB_DEBUG>$0:\n====> in Database::delete_groups SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to delete values via << $sql >>"
            if! do_update($sql,"Groups", $options_ref, $error_strings_ref);
    }    
    return 1;
}
sub delete_package {
    my ($package_name,
        $options_ref,
        $error_strings_ref,
        $package_version) = @_;
    my $sql = "DELETE FROM Packages WHERE package='$package_name' ";
    print "DB_DEBUG>$0:\n====> in Database::delete_package SQL : $sql\n" if $$options_ref{debug};
    $sql .= ($package_version?"AND version='$package_version'":"");
    return do_update($sql,"Packages", $options_ref, $error_strings_ref);
}    

sub delete_node {
    my ($node_name,
        $options_ref,
        $error_strings_ref) = @_;
    my $node_ref = get_node_info_with_name($node_name,$options_ref,$error_strings_ref);    
    my $node_id = $$node_ref{id};
    return 1 if !$node_id;

    delete_group_node($node_id,$options_ref,$error_strings_ref);
    delete_node_packages($node_id,$options_ref,$error_strings_ref);
    my $sql = "DELETE FROM Nodes ";
    print "DB_DEBUG>$0:\n====> in Database::delete_node SQL : $sql\n" if $$options_ref{debug};
    $sql .= ($node_name?"WHERE name='$node_name'":"");
    return do_update($sql,"Nodes", $options_ref, $error_strings_ref);
}    

sub delete_node_packages {
    my ($node_id,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "DELETE FROM Node_Package_Status WHERE node_id=$node_id";
    print "DB_DEBUG>$0:\n====> in Database::delete_node_package_status SQL : $sql\n" if $$options_ref{debug};
    return do_update($sql,"Node_Package_Status", $options_ref, $error_strings_ref);
}


sub insert_packages {
    my ($passed_ref, $table,
        $name,$path,$table_fields_ref,
        $passed_options_ref,$passed_error_strings_ref) = @_;

    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my ( $options_ref, $error_strings_ref ) = fake_missing_parameters
    ( $passed_options_ref, $passed_error_strings_ref );        
    my $sql = "INSERT INTO $table ( ";
    my $sql_values = " VALUES ( ";
    my $flag = 0;
    my $comma = "";
    $sql .= "path, package, ";
    $sql_values .= "'$path', '$name', ";
    foreach my $key (keys %$passed_ref){
        # If a field name is "group", "__" should be added
        # in front of $key to avoid the conflict of reserved keys

        $key = ( $key eq "maintainer" || $key eq "packager"?$key . "_name":$key );
        
        if( $$table_fields_ref{$table}->{$key} && $key ne "package-specific-attribute"){
            $key = ( $key eq "group"?"__$key":$key);
            $key = ( $key eq "class"?"__$key":$key);
            $comma = ", " if $flag;
            $sql .= "$comma $key";
            $flag = 1;
            $key = ( $key eq "__group"?"group":$key);
            $key = ( $key eq "__class"?"class":$key);
            my $value;
            if( $key eq "version" ){
                my $ver_ref = $passed_ref->{$key};
                $value = "$ver_ref->{major}.$ver_ref->{minor}" .
                    ($ver_ref->{subversion}?".$ver_ref->{subversion}":"") .
                    "-$ver_ref->{release}";
                $value =~ s#'#\\'#g;    
                my @pkg_versions=( "major","minor","subversion",
                                    "release", "epoch" );
                $value = "$value', "; 
                foreach my $ver (@pkg_versions){
                    my $tmp_value = $ver_ref->{$ver};
                    if(! $tmp_value ){
                        $tmp_value = "";
                    }else{
                        $tmp_value =~ s#'#\\'#g;
                    }
                    $value .=
                        ( $ver ne "epoch"?"'$tmp_value', ":"'$tmp_value");
                    $sql .= ", version_$ver";
                }    
            }elsif ( $key eq "maintainer_name" || $key eq "packager_name" ){
                $key = ($key eq "maintainer_name"?"maintainer":"packager");
                $sql .= ", $key" .  "_email";
                $value = $passed_ref->{$key}->{name} . "', '"
                        . $passed_ref->{$key}->{email}; 
            }else{
                $value = ($passed_ref->{$key}?trimwhitespace($passed_ref->{$key}):""); 
                $value =~ s#'#\\'#g;
            }
            $sql_values .= "$comma '$value'";
        }
    }
    $sql .= ") $sql_values )\n";

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::insert_packages SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    print "DB_DEBUG>$0:\n====> in Database::insert_packages: Inserting package($name) into Packages\n" if $$options_ref{verbose};
    my $success = oda::do_sql_command($options_ref,
            $sql,
            "INSERT Table into $table",
            "Failed to insert values into $table table",
            $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return  $success;
}

sub insert_pkg_rpmlist {
    my ($passed_ref,$table,$package_id,$options_ref,$error_strings_ref) = @_;
    my $sql = "INSERT INTO $table ( ";
    my $sql_values = " VALUES ( ";
    
    my $group_name = "";
    my $group_arch = "";
    my $distro = "";
    my $distro_version = "";
    $sql .= "package_id";
    $sql_values .= "'$package_id'";

    my $filter;
    if( ref($passed_ref) eq "ARRAY") {
        foreach my $ref (@$passed_ref){
            $filter = $ref->{filter};
            if ( ref($ref->{filter}) eq "ARRAY" ){
                foreach my $each_filter (@$filter){
                    insert_pkg_rpmlist_helper($sql, $sql_values, $each_filter, $ref, $table);
                }
            }else{
                insert_pkg_rpmlist_helper($sql, $sql_values, $filter, $ref, $table);
            }
        }
    }else{
        $filter = $passed_ref->{filter};
        if ( ref($passed_ref->{filter}) eq "ARRAY" ){
            foreach my $each_filter (@$filter){
                insert_pkg_rpmlist_helper($sql, $sql_values, $each_filter, $passed_ref, $table);
            }
        }else{
            insert_pkg_rpmlist_helper($sql, $sql_values, $filter, $passed_ref, $table,$options_ref,$error_strings_ref);
        }
    }   
}

sub insert_pkg_rpmlist_helper {
    my ($sql, $sql_values, $filter, $passed_ref, $table,$options_ref,$error_strings_ref) = @_;
    my $group_name = ($filter->{group}?$filter->{group}:"all");
    my $group_arch = ($filter->{architecture}?$filter->{architecture}:"all");
    my $distro = ($filter->{distribution}->{name}?$filter->{distribution}->{name}:"all");
    my $distro_version = ($filter->{distribution}->{version}?$filter->{distribution}->{version}:"all");
    my $inner_sql = "$sql, group_name, group_arch, distro, distro_version"; 
    my $inner_sql_values = "$sql_values, '$group_name','$group_arch','$distro','$distro_version'"; 
    insert_rpms( $inner_sql, $inner_sql_values, $passed_ref, $table,$options_ref,$error_strings_ref);
}

sub insert_rpms {
    my ($sql, $sql_values, $passed_ref, $table, $options_ref, $error_strings_ref) = @_;
    my $rpm;
    print "DB_DEBUG>$0:\n====> in Database::insert_rpms : Inserting the entries of Packages_rpmlists\n"
        if $$options_ref{verbose};
    if (ref($passed_ref) eq "ARRAY"){
        foreach my $ref (@$passed_ref){
            $rpm = $ref->{pkg};
            if ( ref($rpm) eq "ARRAY" ){
                foreach my $each_rpm (@$rpm){
                    my $inner_sql_values = "$sql_values, '$each_rpm' ";
                    my $inner_sql = "$sql, rpm ) $inner_sql_values)";
                    print "DB_DEBUG>$0:\n====> in Database::insert_rpms SQL : $inner_sql\n" if $$options_ref{debug};
                    do_insert($inner_sql, $table,$options_ref,$error_strings_ref);
                }
            }else{
                my $inner_sql_values = "$sql_values, '". trimwhitespace($rpm)."' ";
                my $inner_sql .= "$sql, rpm ) $inner_sql_values )\n";
                print "DB_DEBUG>$0:\n====> in Database::insert_rpms SQL : $inner_sql\n" if $$options_ref{debug};
                do_insert($inner_sql, $table,$options_ref,$error_strings_ref);
            }
        }    
    }else{
        $rpm = $passed_ref->{pkg};
        if ( ref($rpm) eq "ARRAY" ){
            foreach my $each_rpm (@$rpm){
                my $inner_sql_values = "$sql_values, '$each_rpm' ";
                my $inner_sql = "$sql, rpm ) $inner_sql_values)";
                print "DB_DEBUG>$0:\n====> in Database::insert_rpms SQL : $inner_sql\n" if $$options_ref{debug};
                do_insert($inner_sql, $table,$options_ref,$error_strings_ref);
            }
        }else{
            my $inner_sql_values = "$sql_values, '". trimwhitespace($rpm)."' ";
            my $inner_sql .= "$sql, rpm ) $inner_sql_values )\n";
            print "DB_DEBUG>$0:\n====> in Database::insert_rpms SQL : $inner_sql\n" if $$options_ref{debug};
            do_insert($inner_sql, $table,$options_ref,$error_strings_ref);
        }
    }    
}


# links a node nic to a network in the database
#
sub link_node_nic_to_network {

    my ( $node_name, $nic_name, $network_name, $options_ref, $error_strings_ref ) = @_;

    my $sql = "SELECT Nodes.id, Networks.n_id FROM Nodes, Networks WHERE Nodes.name='$node_name' AND Networks.name='$network_name' ";
    my @results = ();
    my @error_strings = ();
    oda::do_query(\%options,
                $sql,
                \@results,
                \@error_strings);
    my $res_ref = pop @results;
    my $node_id = $$res_ref{"id"};
    my $network_id = $$res_ref{"n_id"};
    my $command =
    "UPDATE Nics SET network_id=$network_id WHERE name='$nic_name' AND node_id=$node_id ";
    print "DB_DEBUG>$0:\n====> in Database::link_node_nic_to_network linking node $node_name nic $nic_name to network $network_name using command <$command>\n"
    if $$options_ref{debug};
    print "DB_DEBUG>$0:\n====> in Database::link_node_nic_to_network Linking node $node_name nic $nic_name to network $network_name.\n"
        if $$options_ref{verbose} && ! $$options_ref{debug};
    
    return do_update($command,"Nics",$options_ref,$error_strings_ref);
}



sub update_node {
    my ($node,
        $field_value_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "UPDATE Nodes SET ";
    my $flag = 0;
    my $comma = "";
    while ( my($field,$value) = each %$field_value_ref ){
        $comma = "," if $flag;
        $sql .= "$comma $field='$value'";
        $flag = 1;
    }    
    $sql .= " WHERE name='$node' ";
    print "DB_DEBUG>$0:\n====> in Database::update_node SQL : $sql\n" if $$options_ref{debug};
    return  do_update($sql,"Nodes", $options_ref, $error_strings_ref);
}

# For normal oscar package installation, 
# the value of  "requested" filed has the following.
# 1 : should_not_be_installed.
# 2 : should_be_installed
# 8 : finished
sub update_node_package_status {
    my ($options_ref,
        $node,
        $passed_pkg,
        $requested,
        $error_strings_ref,
        $passed_ver) = @_;
    $requested = 1 if ! $requested;    
    my $packages;
    if (ref($passed_pkg) eq "ARRAY"){
        $packages = $passed_pkg;
    }else{
        my %opkg = ();
        my @temp_packages = ();
        $opkg{package} = $passed_pkg;
        $opkg{version} = $passed_ver;
        push @temp_packages, \%opkg;
        $packages = \@temp_packages;
    }    
    my $node_ref = get_node_info_with_name($node,$options_ref,$error_strings_ref);
    my $node_id = $$node_ref{id};
    foreach my $pkg_ref (@$packages) {
        my $opkg = $$pkg_ref{package};
        my $ver = $$pkg_ref{version};
        my $package_ref = get_package_info_with_name($opkg,$options_ref,$error_strings_ref,$ver);
        my $package_id = $$package_ref{id};
        my %field_value_hash = ("requested" => $requested);
        my $where = "WHERE package_id=$package_id AND node_id=$node_id";
        if( $requested == 8 && 
            ( $$options_ref{debug} || defined($ENV{DEBUG_OSCAR_WIZARD}) ) ){
            print "DB_DEBUG>$0:\n====> in Database::update_node_package_status Updating the status of $opkg to \"installed\".\n";
        } elsif ( $requested == 2 && 
            ( $$options_ref{debug} || defined($ENV{DEBUG_OSCAR_WIZARD}) ) ) {
            print "DB_DEBUG>$0:\n====> in Database::update_node_package_status Updating the status of $opkg to \"should be installed\".\n";
        } elsif ( $requested == 1 && 
            ( $$options_ref{debug} || defined($ENV{DEBUG_OSCAR_WIZARD}) ) ) {
            print "DB_DEBUG>$0:\n====> in Database::update_node_package_status Updating the status of $opkg to \"should not be installed\".\n";
        }
        my @results = ();
        my $table = "Node_Package_Status";
        get_node_package_status_with_node_package($node,$opkg,\@results,$options_ref,$error_strings_ref);
        if (@results) {
            die "DB_DEBUG>$0:\n====>Failed to update the status of $opkg"
                if(!update_table($options_ref,$table,\%field_value_hash, $where, $error_strings_ref));
        } else {
            %field_value_hash = ("node_id" => $node_id,
                                 "package_id"=>$package_id,
                                 "requested" => $requested);
            die "DB_DEBUG>$0:\n====>Failed to insert values into table $table"
                if(!insert_into_table ($options_ref,$table,\%field_value_hash,$error_strings_ref));
        }
#        $table = "Node_Packages";
#        delete_table($options_ref,$table,$where,$error_strings_ref);
#        %field_value_hash = ("node_id" => $node_id,
#                             "package_id"=>$package_id);
#        die "DB_DEBUG>$0:\n====>Failed to insert values into table $table"
#            if(!insert_into_table ($options_ref,$table,\%field_value_hash,$error_strings_ref));
    }
    return 1;
}

sub update_packages {
    my ($passed_ref, $table,$package_id,
        $name,$path,$table_fields_ref,
        $options_ref,$error_strings_ref) = @_;
    my $sql = "UPDATE $table SET ";
    my $sql_values = " VALUES ( ";
    my $flag = 0;
    my $comma = "";
    $sql .= "path='$path', package='$name', ";
    foreach my $key (keys %$passed_ref){
        # If a field name is "group", "__" should be added
        # in front of $key to avoid the conflict of reserved keys

        $key = ( $key eq "maintainer" || $key eq "packager"?$key . "_name":$key );
        
        if( $$table_fields_ref{$table}->{$key} && $key ne "package-specific-attribute"){
            $comma = ", " if $flag;
            $key = ( $key eq "group"?"__$key":$key);
            $key = ( $key eq "class"?"__$key":$key);
            $sql .= "$comma $key=";
            $flag = 1;
            $key = ( $key eq "__group"?"group":$key);
            $key = ( $key eq "__class"?"class":$key);
            my $value;
            if( $key eq "version" ){
                my $ver_ref = $passed_ref->{$key};
                $value = "$ver_ref->{major}.$ver_ref->{minor}" .
                    ($ver_ref->{subversion}?".$ver_ref->{subversion}":"") .
                    "-$ver_ref->{release}";
                $value =~ s#'#\\'#g;    
                my @pkg_versions=( "major","minor","subversion",
                                    "release", "epoch" );
                $sql .="'$value', "; 
                foreach my $ver (@pkg_versions){
                    my $tmp_value = $ver_ref->{$ver};
                    if(! $tmp_value ){
                        $tmp_value = "";
                    }else{
                        $tmp_value =~ s#'#\\'#g;
                    }
                    $value =
                        ( $ver ne "epoch"?"'$tmp_value', ":"'$tmp_value'");
                    $sql .= " version_$ver=$value";
                }    
            }elsif ( $key eq "maintainer_name" || $key eq "packager_name" ){
                $key = ($key eq "maintainer_name"?"maintainer":"packager");
                $sql .= "'". $passed_ref->{$key}->{name}. "', $key" .
                     "_email='". $passed_ref->{$key}->{email} . "'";
            }else{
                $value = ($passed_ref->{$key}?trimwhitespace($passed_ref->{$key}):""); 
                $value =~ s#'#\\'#g;
                $sql .= "'$value'";
            }
        }
    }
    $sql .= " WHERE id=$package_id\n";

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::update_packages SQL : $sql\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $success = oda::do_sql_command($options_ref,
                    $sql,
                    "UPDATE Table, $table",
                    "Failed to update $table table",
                    $error_strings_ref);
    $error_strings_ref = \@error_strings;
    return $success;
}

sub set_all_groups {
    my ($groups_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Groups";
    print "DB_DEBUG>$0:\n====> in Database::set_all_groups SQL : $sql\n" if $$options_ref{debug};
    my @groups = ();
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@groups, $options_ref, $error_strings_ref);
    if(!@groups){ 
        foreach my $group (keys %$groups_ref){
            set_groups($group,$options_ref,$error_strings_ref,$$groups_ref{$group});
        }
    }
    return 1;
}

sub set_group_nodes {
    my ($group,
        $nodes_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my @groups = ();
    my $group_ref = get_groups(\@groups, $options_ref,$error_strings_ref,$group);
    my $group_id = $$group_ref{id};
    my %field_value_hash = ( "group_id" => $group_id );
    my $success = 0;
    foreach my $node (@$nodes_ref){
        my $node_ref = get_node_info_with_name($node,$options_ref,$error_strings_ref);    
        my $node_id = $$node_ref{id};
        my $sql = "SELECT * FROM Group_Nodes WHERE group_name='$group' ".
                  "AND node_id=$node_id";
        my @results = ();
        print "DB_DEBUG>$0:\n====> in Database::set_group_nodes SQL : $sql\n" if $$options_ref{debug};
        do_select($sql,\@results,$options_ref,$error_strings_ref);
        if(!@results){
            $sql = "INSERT INTO Group_Nodes VALUES('$group', $node_id )";
            print "DB_DEBUG>$0:\n====> in Database::set_group_nodes SQL : $sql\n" if $$options_ref{debug};
            $success = do_insert($sql,"Group_Nodes",$options_ref,$error_strings_ref);
            $success = update_node($node,\%field_value_hash,$options_ref,$error_strings_ref);
            last if ! $success;
        }    
    }    
    return $success;              
}

sub set_group_packages {
    my ($group,
        $package,
        $selected,
        $options_ref,
        $error_strings_ref) = @_;
    $group = get_selected_group($options_ref,$error_strings_ref)
        if(!$group);
    my @results = ();    
    my $sql = "SELECT Packages.id, Packages.package " .
              "From Packages, Group_Packages " .
              "WHERE Packages.id=Group_Packages.package_id ".
              "AND Group_Packages.group_name='$group' " .
              "AND Packages.package='$package'";
    print "DB_DEBUG>$0:\n====> in Database::set_group_packages SQL : $sql\n" if $$options_ref{debug};
    do_select($sql,\@results,$options_ref,$error_strings_ref);
    if (!@results){
        $sql = "INSERT INTO Group_Packages (group_name, package_id, selected) ".
               "SELECT '$group', id, $selected FROM Packages ".
               "WHERE package='$package'";
        print "DB_DEBUG>$0:\n====> in Database::set_group_packages SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if !do_update($sql,"Group_Packages",$options_ref,$error_strings_ref);
    }else{
        my $result_ref = pop @results;
        my $package_id = $$result_ref{id};
        $sql = "UPDATE Group_Packages SET selected=$selected ".
            "WHERE group_name='$group' ".
            "AND package_id='$package_id'";
        print "DB_DEBUG>$0:\n====> in Database::set_group_packages SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to update values via << $sql >>"
            if !do_update($sql,"Group_Packages",$options_ref,$error_strings_ref);
    }
    update_node_package_status(
          $options_ref,"oscar_server",$package,$selected,$error_strings_ref);
    return 1;
}

sub set_groups {
    my ($group,
        $options_ref,
        $error_strings_ref,
        $type) = @_;
    $type = "package" if ! $type;
    my @results = ();
    get_groups(\@results,$options_ref,$error_strings_ref,$group);
    if(!@results){
        my $sql = "INSERT INTO Groups (name,type) VALUES ('$group','$type')";
        print "DB_DEBUG>$0:\n====> in Database::set_groups SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if! do_insert($sql,"Groups", $options_ref, $error_strings_ref);
    }    
    return 1;
}

sub set_groups_selected {
    my ($group,
        $options_ref,
        $error_strings_ref) = @_;
    my @results = ();
    get_groups(\@results,$options_ref,$error_strings_ref,$group);
    if(@results){
        # Initialize the "selected" flag (selected = 0)
        my $sql = "UPDATE Groups SET selected=0";
        print "DB_DEBUG>$0:\n====> in Database::set_groups_selected SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to update values via << $sql >>"
            if! do_insert($sql,"Groups", $options_ref, $error_strings_ref);

        # Set the seleted group to have "selected" flag
        # (selected = 1)
        $sql = "UPDATE Groups SET selected=1 WHERE name='$group'";
        print "DB_DEBUG>$0:\n====> in Database::set_groups_selected SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to update values via << $sql >>"
            if! do_insert($sql,"Groups", $options_ref, $error_strings_ref);
    }    
    return 1;
}

sub set_image_packages {
    my ($image,
        $package,
        $options_ref,
        $error_strings_ref) = @_;
    my $image_ref = get_image_info_with_name($image,$options_ref,$error_strings_ref);
    croak("Image $image not found in OSCAR Database") unless ($image_ref);
    my $image_id = $$image_ref{id};
    my $package_ref = get_package_info_with_name($package,$options_ref,$error_strings_ref);
    my $package_id = $$package_ref{id};
    my $sql = "SELECT * FROM Image_Packages WHERE image_id=$image_id AND package_id=$package_id";
    print "DB_DEBUG>$0:\n====> in Database::set_image_packages SQL : $sql\n" if $$options_ref{debug};
    my @images = ();
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@images, $options_ref, $error_strings_ref);
    if(!@images){ 
        $sql = "INSERT INTO Image_Packages (image_id,package_id) VALUES ".
            "($image_id,$package_id)";
        print "DB_DEBUG>$0:\n====> in Database::set_image_packages SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if! do_insert($sql,"Image_Packages", $options_ref, $error_strings_ref);
    }
    return 1;
}    

sub set_images{
    my ($image_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $imgname = $$image_ref{name};
    my $architecture = $$image_ref{architecture};
    my $images = get_image_info_with_name($imgname,$options_ref,$error_strings_ref);
    my $imagepath = $$image_ref{path};
    my $sql = "";
    if(!$images){ 
        $sql = "INSERT INTO Images (name,architecture,path) VALUES ".
            "('$imgname','$architecture','$imagepath')";
        print "DB_DEBUG>$0:\n====> in Database::set_images SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if! do_insert($sql,"Images", $options_ref, $error_strings_ref);
    }else{
        $sql = "UPDATE Images SET name='$imgname', ". 
               "architecture='$architecture', path='$imagepath' WHERE name='$imgname'";
        print "DB_DEBUG>$0:\n====> in Database::set_images SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to update values via << $sql >>"
            if! do_update($sql,"Images", $options_ref, $error_strings_ref);
    }
    return 1;
}

# Set installation mode for cluster
sub set_install_mode {
    my ($install_mode,
        $options_ref,
        $error_strings_ref) = @_;

    my $cluster = "oscar";
    my $sql = "UPDATE Clusters SET install_mode='$install_mode' WHERE name ='$cluster'";

    print "DB_DEBUG>$0:\n====> in Database::set_install_mode SQL : $sql\n" if $$options_ref{debug};
    return do_update($sql, "Clusters", $options_ref, $error_strings_ref);
}


sub set_node_with_group {
    my ($node,
        $group,
        $options_ref,
        $error_strings_ref,
        $cluster_name) = @_;
    my $sql = "SELECT name FROM Nodes WHERE name='$node'";
    my @nodes = ();
    print "DB_DEBUG>$0:\n====> in Database::set_node_with_group SQL : $sql\n" if $$options_ref{debug};
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@nodes, $options_ref, $error_strings_ref);
    if(!@nodes){ 
        $cluster_name = $CLUSTER_NAME if !$cluster_name;
        my $cluster_ref = get_cluster_info_with_name($cluster_name,$options_ref, $error_strings_ref);
        my $cluster_id = $$cluster_ref{id} if $cluster_ref;
        $sql = "INSERT INTO Nodes (cluster_id, name, group_id) ".
               "SELECT $cluster_id, '$node', id FROM Groups WHERE name='$group'";
        print "DB_DEBUG>$0:\n====> in Database::set_node_with_group SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if! do_insert($sql,"Nodes", $options_ref, $error_strings_ref);
    }
    return 1;
}

sub set_nics_with_node {
    my ($nic,
        $node,
        $field_value_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT Nics.* FROM Nics, Nodes WHERE Nodes.id=Nics.node_id " .
              "AND Nics.name='$nic' AND Nodes.name='$node'";
    print "DB_DEBUG>$0:\n====> in Database::set_nics_with_node SQL : $sql\n" if $$options_ref{debug};
    my @nics = ();
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@nics, $options_ref, $error_strings_ref);

    my $node_ref = get_node_info_with_name($node,$options_ref,$error_strings_ref);
    my $node_id = $$node_ref{id};
    if(!@nics){ 
        $sql = "INSERT INTO Nics ( name, node_id ";
        my $sql_value = " VALUES ('$nic', $node_id ";
        if( $field_value_ref ){
            while (my ($field, $value) = each %$field_value_ref){
                $sql .= ", $field";
                $sql_value .= ", '$value'";
            }
        }
        $sql .= " ) $sql_value )";
        print "DB_DEBUG>$0:\n====> in Database::set_nics_with_node SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if! do_insert($sql,"Nodes", $options_ref, $error_strings_ref);
    }else{
        $sql = "UPDATE Nics SET ";
        my $flag = 0;
        my $comma = "";
        if( $field_value_ref ){
            while (my ($field, $value) = each %$field_value_ref){
                $comma = ", " if $flag;
                $sql .= "$comma $field='$value'";
                $flag = 1;
            }
            $sql .= " WHERE name='$nic' AND node_id=$node_id ";
            print "DB_DEBUG>$0:\n====> in Database::set_nics_with_node SQL : $sql\n" if $$options_ref{debug};
            die "DB_DEBUG>$0:\n====>Failed to update values via << $sql >>"
                if! do_update($sql,"Nics", $options_ref, $error_strings_ref);
        }
    }
    return 1;
}

sub set_status {
    my ($options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Status";
    print "DB_DEBUG>$0:\n====> in Database::set_status SQL : $sql\n" if $$options_ref{debug};
    my @status = ();
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@status, $options_ref, $error_strings_ref);
    if(!@status){ 
        foreach my $status (
                            "should_not_be_installed",
                            "should_be_installed",
                            "undefined_1",
                            "undefined_2",
                            "undefined_3",
                            "undefined_4",
                            "undefined_5",
                            "finished"
                            ){
#   OLD Status values                            
#                          ( "installable", "installed",
#                            "install_allowed","should_be_installed", 
#                            "should_be_uninstalled","uninstalled",
#                            "finished")
                            
            $sql = "INSERT INTO Status (name) VALUES ('$status')";
            print "DB_DEBUG>$0:\n====> in Database::set_status SQL : $sql\n" if $$options_ref{debug};
            die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
                if! do_insert($sql,"Nodes", $options_ref, $error_strings_ref);
        }
    }
    return 1;
}



######################################################################
#
#       Miscellaneous database subroutines
#
######################################################################



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
    my (  $passed_options_ref,
          $passed_error_strings_ref ) = @_;

    my %options = ( 'debug'         => 0,
                    'raw'           => 0,
                    'verbose'       => 0 );
    # take care of faking any non-passed input parameters, and
    # set any options to their default values if not already set
    my @ignored_error_strings;
    my $error_strings_ref = ( defined $passed_error_strings_ref ) ?
    $passed_error_strings_ref : \@ignored_error_strings;

    my $options_ref;
    if (ref($passed_options_ref) eq "HASH" && defined $passed_options_ref){
        $options_ref = $passed_options_ref;
    } else {
        $options_ref = \%options;
    }

    print "DB_DEBUG>$0:\n====> in Database.pm::fake_missing_parameters handling"
        . " the missing parameters"
        if $$options_ref{verbose};

    return ( $options_ref,
         $error_strings_ref );
}


sub print_error_strings {
    my $passed_errors_ref = shift;
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;

    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
        warn shift @$error_strings_ref while @$error_strings_ref;
    }
    $error_strings_ref = \@error_strings;
}


sub trimwhitespace($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}



######################################################################
#
#       LOCK / UNLOCK database subroutines
#
######################################################################

#
# NEST
# This subroutine is renamed from database_execute_command and represents
# the $command_args_ref in the subroutine is already locked in the outer lock block.
# Basically this subroutine is the exactly same as database_execute_command
# except for its name.
#
sub dec_already_locked {

    my ( $sql_command,
     $passed_errors_ref ) = @_;

    # sometimes this is called without a database_connected being 
    # called first, so we have to connect first if that is the case
    ( my $was_connected_flag = $database_connected ) ||
	database_connect( undef, $passed_errors_ref ) ||
        return undef;

    # execute the command
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my $success =  oda::do_sql_command( $options_ref,
                                $sql_command,
                                undef,
                                undef,
                                $error_strings_ref );
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
    warn shift @$error_strings_ref while @$error_strings_ref;
    }

    # if we weren't connected to the database when called, disconnect
    database_disconnect() if ! $was_connected_flag;

    return $success;
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


sub locking {
    my ( $type_of_lock,
         $options_ref,
         $passed_tables_ref,
     $error_strings_ref,
     ) = @_;
    my @empty_tables = ();
    my $tables_ref = ( defined $passed_tables_ref ) ? $passed_tables_ref : \@empty_tables;

    my $msg = "DB_DEBUG>$0:\n====> in oda:";
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
            "DB_DEBUG>$0:\n====> table <$table_name> does not exist in " .
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


    print "DB_DEBUG>$0:\n====> in oda:unlock \n"
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


#
# NEST
# This is locking a single database_execute_command with some argurments
# Basically Lock -> 1 oda::execute_command -> unlock
# $type_of_lock is optional, if it is omitted, the default type of lock is "READ".
# The required argument is $tables_ref, which is the reference of the list of tables.
# The other arguments are the same as the database_execute_command.
#
sub single_dec_locked {

    my ( $command_args_ref,
         $type_of_lock,
         $tables_ref,
         $results_ref,
     $passed_errors_ref ) = @_;

    # execute the command
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;
    my @tables = ();
    if ( (ref($tables_ref) eq "ARRAY")
        && (defined $tables_ref)
        && (scalar @$tables_ref != 0) ){
        @tables = @$tables_ref;
    } else {
        #chomp(@tables = oda::list_tables);
        my $all_tables_ref = oda::list_tables( $options_ref, $error_strings_ref );
        foreach my $table (keys %$all_tables_ref){
            push @tables, $table;
        }    
    }
    my $lock_type = (defined $type_of_lock)? $type_of_lock : "READ";
    # START LOCKING FOR NEST && open the database
    my %options = ();
#    if(! locking($lock_type, $options_ref, \@tables, $error_strings_ref)){
#        return 0;
        #die "DB_DEBUG>$0:\n====> cannot connect to oda database";
#    }
    my $success = oda::do_query( $options_ref,
                    $command_args_ref,
                    $results_ref,
                    $error_strings_ref );
    # UNLOCKING FOR NEST
    unlock($options_ref, $error_strings_ref);
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
    warn shift @$error_strings_ref while @$error_strings_ref;
    }
    
    return $success;
}

1;
