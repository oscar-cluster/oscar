package OSCAR::Database_generic;

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

#
# Copyright (c) 2007 The Trustees of Indiana University.  
#                    All rights reserved.
# 

#
# $Id$
#

# This is a new version of ODA with somewhat generic subroutines

# Like Database.pm, Database_generic.pm, located at the next level
# of the ODA hierarchy, is an abstract Perl module to handle directly
# all the database operations under the control of oda.pm. The Perl 
# subroutines defined at Database_generic.pm are used at Database.pm
# and also can be used at any other OSCAR codes to directly get database
# queries without browsing all the subroutines in Database.pm
#


# Most frequently used internal subroutines
# - do_select
# - do_update
# - do_insert


# Frequently used External subroutines
# - insert_into_table
# - delete_table
# - update_table
# - select_table

####  OSCAR TABLES  ####
#
# Clusters
# Groups
# Status
# Packages
# Images
# Nodes
# OscarFileServer
# Networks
# Nics
# Packages_rpmlists
# Packages_servicelists
# Packages_switcher
# Packages_conflicts
# Packages_requires
# Packages_provides
# Packages_config
# Node_Package_Status
# Group_Nodes
# Group_Packages
# Image_Package_Status
#
########################

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
my $OSCAR_SERVER = "oscar_server";

$options{debug} = 1 
    if (exists $ENV{OSCAR_VERBOSE} && $ENV{OSCAR_VERBOSE} == 10)
        || $ENV{OSCAR_DB_DEBUG};

@EXPORT = qw( 
              create_table
              delete_table
              insert_into_table
              select_table
              update_table

              do_insert
              do_select
              do_update
	      );


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
    my $cmd = "mysql -u $$options_ref{user} -p$$options_ref{password} oscar < $sql_file";

    my $debug_msg = "DB_DEBUG>$0:\n====> in Database::create_table runs the command : $cmd\n";
    print "$debug_msg" if $$options_ref{debug};
    push @$error_strings_ref, $debug_msg;

    my $success = oda::do_shell_command($options_ref, "$cmd", $error_strings_ref);

    $error_strings_ref = \@error_strings;
    return  $success;
}    


1;
