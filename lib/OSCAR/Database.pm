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
# Copyright (c) 2005-2007 The Trustees of Indiana University.  
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
use OSCAR::Database_generic;
use OSCAR::oda;
use Data::Dumper;

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

@EXPORT = qw( database_connect 
              database_disconnect 

              delete_package
              delete_node
              delete_group_packages
              delete_groups
              del_pkgconfig_vars
              get_client_nodes
              get_client_nodes_info
              get_cluster_info_with_name
              get_gateway
              get_group_packages_with_groupname
              get_groups
              get_groups_for_packages
              get_headnode_iface
              get_image_info_with_name
              get_image_package_status_with_image
              get_image_package_status_with_image_package
              get_install_mode
              get_installable_packages
              get_manage_status
              get_networks
              get_nics_info_with_node
              get_nics_with_name_node
              get_nodes
              get_node_info_with_name
              get_node_package_status_with_group_node
              get_node_package_status_with_node
              get_node_package_status_with_node_package
              get_package_info_with_name
              get_packages
              get_packages_related_with_package
              get_packages_related_with_name
              get_packages_switcher
              get_packages_servicelists
              get_packages_with_class
              get_pkgconfig_vars
              get_selected_group
              get_selected_group_packages
              get_selected_packages
              get_status_name
              get_status_num
              get_pkg_status_num
              get_unselected_group_packages
              get_unselected_packages
              get_wizard_status
              insert_packages
              insert_pkg_rpmlist
              is_installed_on_node
              link_node_nic_to_network
    	      list_selected_packages
    	      pkgs_of_opkg
              pkgconfig_values
              set_all_groups
              set_group_packages
              set_group_nodes
              set_groups
              set_groups_selected
              set_images
              set_image_packages
              set_install_mode
              set_manage_status
              set_nics_with_node
              set_node_with_group
              set_pkgconfig_var
              set_status
              set_wizard_status
              update_image_package_status_hash
              update_node
              update_node_package_status_hash
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
    if (exists($sel{"arch"}) && exists($sel{"distro"}) &&
	     exists($sel{"distro_ver"})) {
        $architecture = $sel{"arch"};
        $distribution = $sel{"distro"};
        $distribution_version = $sel{"distro_ver"};

    } else {
        if (!exists($sel{"os"})) {
            if (exists($sel{"chroot"})) {
                $chroot = $sel{"chroot"};
            } else {
                $chroot = "/";
            }
	        $os = distro_detect_or_die($chroot);
        } else {
            $os = $sel{"os"};
        }
        $architecture = $os->{"arch"};
        $distribution = $os->{"compat_distro"};
        $distribution_version = $os->{"compat_distrover"};
    }
    if (exists($sel{"group"})) {
    	$group = $sel{"group"};
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

sub get_nodes {
    my ($results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Nodes";
    print "DB_DEBUG>$0:\n====> in Database::get_nodes SQL : $sql\n" if $$options_ref{debug};
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


sub get_packages {
    my ($results_ref,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Packages";
    print "DB_DEBUG>$0:\n====> in Database::get_packagess SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results_ref, $options_ref, $error_strings_ref);
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

# This is called only by "DelNode.pm" and if group_name is not specified,
# it will assume that you are querying for all the client nodes because we
# can not remove oscar_server node here.
# As Bernard suggested, this should query from installed packages.
# The extra condition to check to see if a package is installed or not
# is added.
sub get_packages_servicelists {
    my ($results_ref,
        $group_name,
        $options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT distinct P.package, S.service " .
              "FROM Packages P, Packages_servicelists S, Node_Package_Status N, " .
              "Group_Nodes G " .
              "WHERE P.id=S.package_id AND N.package_id=S.package_id ".
              "AND G.node_id=N.node_id AND N.requested=8 ";
    $sql .= ($group_name?" AND G.group_name='$group_name' AND S.group_name='$group_name'":" AND S.group_name!='$OSCAR_SERVER'");          
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

# Get the list of packages to install at the step "PackageInUn".
# This subroutine checks the flag "selected" and get the list of
# packages from the table "Node_Package_Status" where the "selected"
# flag is 2.

# Flag : selected
# 0 -> default (Selector has not touched the field)
# 1 -> unselected
# 2 -> selected
sub get_selected_packages {
    my ($results,
        $options_ref,
        $error_strings_ref,
        $node_name) = @_;

    $node_name = $OSCAR_SERVER if (!$node_name);

    my $sql = "SELECT Packages.package, Node_Package_Status.* " .
             "From Packages, Node_Package_Status, Nodes ".
             "WHERE Node_Package_Status.package_id=Packages.id ".
             "AND Node_Package_Status.node_id=Nodes.id ".
             "AND Node_Package_Status.selected=2 ".
             "AND Nodes.name='$node_name'";
    print "DB_DEBUG>$0:\n====> in Database::is_installed_on_node SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

# Get the list of packages to uninstall at the step "PackageInUn".
# This subroutine checks the flag "selected" and get the list of
# packages from the table "Node_Package_Status" where the "selected"
# flag is 1.

# Flag : selected
# 0 -> default (Selector has not touched the field)
# 1 -> unselected
# 2 -> selected
sub get_unselected_packages {
    my ($results,
        $options_ref,
        $error_strings_ref,
        $node_name) = @_;

    $node_name = $OSCAR_SERVER if (!$node_name);

    my $sql = "SELECT Packages.package, Node_Package_Status.* " .
             "From Packages, Node_Package_Status, Nodes ".
             "WHERE Node_Package_Status.package_id=Packages.id ".
             "AND Node_Package_Status.node_id=Nodes.id ".
             "AND Node_Package_Status.selected=1 ".
             "AND Nodes.name='$node_name'";
    print "DB_DEBUG>$0:\n====> in Database::is_installed_on_node SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
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

sub get_image_package_status_with_image {
    my ($image,
        $results,
        $options_ref,
        $error_strings_ref,
        $requested,
        $version) = @_;
        my $sql = "SELECT Packages.package, Image_Package_Status.* " .
                 "From Packages, Image_Package_Status, Images ".
                 "WHERE Node_Package_Status.package_id=Packages.id ".
                 "AND Image_Package_Status.image_id=Images.id ".
                 "AND Images.name='$image'";
        if (defined $requested && $requested ne "") {
            $sql .= " AND Image_Package_Status.requested=$requested ";
        }
        if (defined $version && $version ne "") {
            $sql .= " AND Packages.version=$version ";
        }
    print "DB_DEBUG>$0:\n====> in Database::get_image_package_status_with_image SQL : $sql\n" if $$options_ref{debug};
    return do_select($sql,$results, $options_ref, $error_strings_ref);
}

sub get_image_package_status_with_image_package {
    my ($image,
        $package,
        $results,
        $options_ref,
        $error_strings_ref,
        $requested,
        $version) = @_;
        my $sql = "SELECT Packages.package, Images_Package_Status.* " .
                 "From Packages, Image_Package_Status, Images ".
                 "WHERE Image_Package_Status.package_id=Packages.id ".
                 "AND Image_Package_Status.image_id=Images.id ".
                 "AND Imagse.name='$image' AND Packages.package='$package'";
        if(defined $requested && $requested ne ""){
            $sql .= " AND Image_Package_Status.requested=$requested ";
        }
        if(defined $version && $version ne ""){
            $sql .= " AND Packages.version=$version ";
        }
    print "DB_DEBUG>$0:\n====> in Database::get_image_package_status_with_image_package SQL : $sql\n" if $$options_ref{debug};
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


# Return the wizard step status
sub get_wizard_status {
    my ($options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Wizard_status";
    my $sql_2 = "SELECT * FROM Images";
    my @results = ();
    my $success = do_select($sql,\@results,$options_ref,$error_strings_ref);
    my %wizard_status = ();
    if ($success){
        foreach my $ref (@results){
            $wizard_status{$$ref{step_name}} = $$ref{status};
        }
    }
    my @res = ();
    my $success_2 = do_select($sql_2,\@res,$options_ref,$error_strings_ref);
    if ($success_2 && @res){
        $wizard_status{"addclients"} = "normal";
        set_wizard_status("addclients",$options_ref,$error_strings_ref);
    }
    return \%wizard_status;
}

# Return the manage step status
sub get_manage_status {
    my ($options_ref,
        $error_strings_ref) = @_;
    my $sql = "SELECT * FROM Manage_status";
    my @results = ();
    my $success = do_select($sql,\@results,$options_ref,$error_strings_ref);
    my %manage_status = ();
    if ($success){
        foreach my $ref (@results){
            $manage_status{$$ref{step_name}} = $$ref{status};
        }
    }
    return \%manage_status;
}

# Initialize the "selected" field in the table "Node_Package_Status"
# to get the table "Node_Package_Status" ready for another "PackageInUn"
# process
sub initialize_selected_flag{
    my ($options_ref,
        $error_strings_ref) = @_;
    my $table = "Node_Package_Status";
    my %field_value_hash = ("selected" => 0);
    my $where = "";
    die "DB_DEBUG>$0:\n====>Failed to update the flag of selected"
        if(!update_table($options_ref,$table,\%field_value_hash, $where, $error_strings_ref));
}        

sub is_installed_on_node {
    my ($package_name,
        $node_name,
        $options_ref,
        $error_strings_ref,
        $selector,
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
    $sql .= ($node_name?"'$node_name'":"'$OSCAR_SERVER'"); 
    if(defined $requested && $requested ne ""){
        if($selector){
            $sql .= " AND Node_Package_Status.ex_status=$requested ";
        }else{
            $sql .= " AND Node_Package_Status.requested=$requested ";
        }    
    }
    if(defined $version && $version ne ""){
        $sql .= " AND Packages.version=$version ";
    }
    print "DB_DEBUG>$0:\n====> in Database::is_installed_on_node SQL : $sql\n" if $$options_ref{debug};
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@result, $options_ref, $error_strings_ref);
    return (@result?1:0);    
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

        # Set "should_not_be_installed" to the package status    
        update_node_package_status(
              $options_ref,$OSCAR_SERVER,$opkg,1,$error_strings_ref);
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

################################################################################
# This function includes given OSCAR Packages into the database                #
################################################################################
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
        $selected,
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
    # If requested is one of the names of the fields being passed in, convert it
	# to the enum version instead of the string
	if($requested && $requested !~ /\d/) {
		$requested = get_status_num($options_ref, $requested, $error_strings_ref);
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
            my $pstatus_ref = pop @results;
            my $ex_status = $$pstatus_ref{ex_status};
            $field_value_hash{requested} = $ex_status if($ex_status == 8 && $requested == 2);
            $field_value_hash{ex_status} = $$pstatus_ref{requested};

            # If $requested is 8(finished), set the "ex_status" to 8
            # because setting "finished" to the "ex_status" prevents
            # package status from being updated incorrectly when a 
            # package is selected/unselected on Seletor.
            #
            # NOTE : the "selected" field is only for PackageInUn
            #
            $field_value_hash{ex_status} = $requested if($requested == 8 && $ex_status != 2);
            $field_value_hash{selected} = $selected if ($selected);
            die "DB_DEBUG>$0:\n====>Failed to update the status of $opkg"
                if(!update_table($options_ref,$table,\%field_value_hash, $where, $error_strings_ref));
        } else {
            %field_value_hash = ("node_id" => $node_id,
                                 "package_id"=>$package_id,
                                 "requested" => $requested);
            die "DB_DEBUG>$0:\n====>Failed to insert values into table $table"
                if(!insert_into_table ($options_ref,$table,\%field_value_hash,$error_strings_ref));
        }
    }
    return 1;
}

# Translates the string representation of a status to the enumerated numeric
# version stored in the database
sub get_status_num {
	my ($options_ref,
		$status,
		$error_strings_ref) = @_;
	
	# Get the internal id for a requested value from the status table
	my @field = ("id");
	my $where = "WHERE name=\'$status\'";
	my @result;
	select_table($options_ref, "Status", \@field, $where, \@result, $error_strings_ref);
	my $status_id = $result[0]->{id};
	
	return $status_id;
}

# Translates the enumerated numeric representation of a status stored in the
# database to a string
sub get_status_name {
	my ($options_ref,
		$status,
		$error_strings_ref) = @_;
	
	# Get the internal id for a requested value from the status table
	my @field = ("name");
	my $where = "WHERE id=\'$status\'";
	my @result;
	select_table($options_ref, "Status", \@field, $where, \@result, $error_strings_ref);
	my $status_name = $result[0]->{name};
	
	return $status_name;
}

# Translates the string representation of a package status to the enumerated
# numeric version stored in the database
sub get_pkg_status_num {
	my ($options_ref,
		$status,
		$error_strings_ref) = @_;
	
	# Get the internal id for a value from the package status table
	my @field = ("id");
	my $where = "WHERE status=\'$status\'";
	my @result;
	select_table($options_ref, "Package_status", \@field, $where, \@result, $error_strings_ref);
	my $status_num = $result[0]->{id};
	
	return $status_num;
}

# Updates the status information for a package by passing in a hash
# The keys in the hash are the names of the database fields (requested, current,
# status, etc.).  The values are the values that should be put
# into the database.
sub update_node_package_status_hash {
	my ($options_ref,
		$node,
		$passed_pkg,
		$field_value_hash,
		$error_strings_ref,
		$passed_ver) = @_;
	my $packages;
	
	# Get the information passed in about a package
	if(ref($passed_pkg) eq "ARRAY") {
		$packages = $passed_pkg;
	} else {
		my %opkg = ();
		my @temp_packages = ();
		$opkg{package} = $passed_pkg;
		$opkg{version} = $passed_ver;
		push @temp_packages, \%opkg;
		$packages = \@temp_packages;
	}
	
	# If requested is one of the names of the fields being passed in, convert it
	# to the enum version instead of the string
	if(exists $$field_value_hash{requested}) {
		$$field_value_hash{requested} = get_status_num($options_ref, $$field_value_hash{requested}, $error_strings_ref);
	}
	
	# If current is one of the names of the fields being passed in, convert it
	# to the enum version instead of the string
	if(exists $$field_value_hash{curr}) {
		$$field_value_hash{curr} = get_status_num($options_ref, $$field_value_hash{curr}, $error_strings_ref);
	}
	
	# If status is one of the names of the fields being passed in, convert it
	# to the enum version instead of the string
	if(exists $$field_value_hash{status}) {
		$$field_value_hash{status} = get_pkg_status_num($options_ref, $$field_value_hash{status}, $error_strings_ref);
	}
	
	# Get the internal id for the node
	my $node_ref = get_node_info_with_name($node,$options_ref,$error_strings_ref);
	my $node_id = $$node_ref{id};
	
	# Get more information about the package
	foreach my $pkg_ref (@$packages) {
		my $opkg = $$pkg_ref{package};
		my $ver = $$pkg_ref{version};
		my $package_ref = get_package_info_with_name($opkg,$options_ref,$error_strings_ref,$ver);
		my $package_id = $$package_ref{id};
		my $where = "WHERE package_id=$package_id AND node_id=$node_id";
		
		# Check to see if there is an entry in the table already
		my @field = ("package_id");
		my @result;
		select_table($options_ref, "Node_Package_Status", \@field, $where, \@result, $error_strings_ref);
		if($result[0]->{package_id} && $result[0]->{package_id} == $package_id) {
			die "DB_DEBUG>$0:\n====>Failed to update the request for $opkg" 
        		if(!update_table($options_ref,"Node_Package_Status",$field_value_hash, $where, $error_strings_ref));
        } else {
        	$$field_value_hash{package_id} = $package_id;
        	$$field_value_hash{node_id} = $node_id;
        	die "DB_DEBUG>$0:\n====>Failed to insert the request for $opkg" 
        		if(!insert_into_table($options_ref,"Node_Package_Status",$field_value_hash, $error_strings_ref));
        }
	}
	return 1;
}

# Updates the status information for a package by passing in a hash
# The keys in the hash are the names of the database fields (requested, current,
# status, etc.).  The values are the values that should be put
# into the database.
sub update_image_package_status_hash {
	my ($options_ref,
		$image,
		$passed_pkg,
		$field_value_hash,
		$error_strings_ref,
		$passed_ver) = @_;
	my $packages;
	
	# Get the information passed in about a package
	if(ref($passed_pkg) eq "ARRAY") {
		$packages = $passed_pkg;
	} else {
		my %opkg = ();
		my @temp_packages = ();
		$opkg{package} = $passed_pkg;
		$opkg{version} = $passed_ver;
		push @temp_packages, \%opkg;
		$packages = \@temp_packages;
	}
	
	# If requested is one of the names of the fields being passed in, convert it
	# to the enum version instead of the string
	if(exists $$field_value_hash{requested}) {
		$$field_value_hash{requested} = get_status_num($options_ref, $$field_value_hash{requested}, $error_strings_ref);
	}
	
	# If current is one of the names of the fields being passed in, convert it
	# to the enum version instead of the string
	if(exists $$field_value_hash{current}) {
		$$field_value_hash{current} = get_status_num($options_ref, $$field_value_hash{current}, $error_strings_ref);
	}
	
	# Get the internal id for the node
	my $image_ref = get_iamge_info_with_name($image,$options_ref,$error_strings_ref);
	my $image_id = $$image_ref{id};
	
	# Get more information about the package
	foreach my $pkg_ref (@$packages) {
		my $opkg = $$pkg_ref{package};
		my $ver = $$pkg_ref{version};
		my $package_ref = get_package_info_with_name($opkg,$options_ref,$error_strings_ref,$ver);
		my $package_id = $$package_ref{id};
		my $where = "WHERE package_id=$package_id AND image_id=$image_id";
		die "DB_DEBUG>$0:\n====>Failed to update the request for $opkg" 
        	if(!update_table($options_ref,"Image_Package_Status",$field_value_hash, $where, $error_strings_ref));
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
        $requested,
        $options_ref,
        $error_strings_ref) = @_;
    $group = get_selected_group($options_ref,$error_strings_ref)
        if(!$group);
    my @results = ();    
    # Update Node_Package_Status to set the "selected" value according to the
    # "requested" value:
    # if requested = 1 then selected = 0
    # if requested >= 2 then selected = 1
    my $selected = 0;
    my $sql = "SELECT Packages.id, Packages.package " .
              "From Packages, Group_Packages " .
              "WHERE Packages.id=Group_Packages.package_id ".
              "AND Group_Packages.group_name='$group' " .
              "AND Packages.package='$package'";
    print "DB_DEBUG>$0:\n====> in Database::set_group_packages SQL : $sql\n" if $$options_ref{debug};
    do_select($sql,\@results,$options_ref,$error_strings_ref);
    if (!@results){
        $selected = 1;
        $sql = "INSERT INTO Group_Packages (group_name, package_id, selected) ".
               "SELECT '$group', id, $selected FROM Packages ".
               "WHERE package='$package'";
        print "DB_DEBUG>$0:\n====> in Database::set_group_packages SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if !do_update($sql,"Group_Packages",$options_ref,$error_strings_ref);
    }else{
        $selected = 1 if ($requested && $requested >= 2);
        my $result_ref = pop @results;
        my $package_id = $$result_ref{id};
        $sql = "UPDATE Group_Packages SET selected=$selected ".
            "WHERE group_name='$group' ".
            "AND package_id='$package_id'";
        print "DB_DEBUG>$0:\n====> in Database::set_group_packages SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to update values via << $sql >>"
            if !do_update($sql,"Group_Packages",$options_ref,$error_strings_ref);
    }

    $requested = 1 if !$requested;
    update_node_package_status(
          $options_ref,$OSCAR_SERVER,$package,$requested,$error_strings_ref);
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
    my $sql = "SELECT * FROM Image_Package_Status WHERE image_id=$image_id AND package_id=$package_id";
    print "DB_DEBUG>$0:\n====> in Database::set_image_packages SQL : $sql\n" if $$options_ref{debug};
    my @images = ();
    die "DB_DEBUG>$0:\n====>Failed to query values via << $sql >>"
        if! do_select($sql,\@images, $options_ref, $error_strings_ref);
    if(!@images){ 
        $sql = "INSERT INTO Image_Package_Status (image_id,package_id) VALUES ".
            "($image_id,$package_id)";
        print "DB_DEBUG>$0:\n====> in Database::set_image_packages SQL : $sql\n" if $$options_ref{debug};
        die "DB_DEBUG>$0:\n====>Failed to insert values via << $sql >>"
            if! do_insert($sql,"Image_Package_Status", $options_ref, $error_strings_ref);
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

# Set the Manage status with a new value
sub set_manage_status{
    my ($step_name, $options_ref, $error_strings_ref) = @_;
    my $sql = "UPDATE Manage_status SET status='normal' WHERE
    step_name='$step_name'";
    return do_update($sql,"Manage_status",$options_ref,$error_strings_ref);
}    

# set package configuration name/value pair
# Usage example:
#   set_pkgconfig_var(opkg => "ganglia" , context => "",
#                     name => "gmond_if", value => [ "eth0" ]);
#
# "value" needs to point to an anonymous array reference!
# The arguments "name" and "context" are optional.
sub set_pkgconfig_var {
    my (%val) = @_;
    if (!exists($val{opkg}) || !exists($val{name}) || !exists($val{value})) {
	croak("missing one of opkg/name/value : ".Dumper(%val));
    }
    if (!exists($val{context}) || $val{context} eq "") {
	$val{context} = "global";
    }
    my (%options, @errors);
    my %sel = %val;
    delete $sel{value};
    my $sql;
    # delete all existing records
    &del_pkgconfig_vars(%sel);

    # get opkg_id first
    my $opkg = $val{opkg};
    delete $val{opkg};

    my $pref = get_package_info_with_name($opkg,\%options,\@errors);
    croak("No package $opkg found!") if (!$pref);
    my $opkg_id = $pref->{id};
    $val{package_id} = $opkg_id;
    my @values = @{$val{value}};
    delete $val{value};

    for my $v (@values) {
	$val{value} = $v;
	$sql = "INSERT INTO Packages_config (".join(", ",(keys(%val))).") " .
	    "VALUES ('" . join("', '",values(%val)) . "')";;
	croak("$0:Failed to insert values via << $sql >>")
	    if !do_insert($sql, "Packages_config", \%options, \@errors);
    }
    return 1;
}

# get package configuration values
# Usage example:
#   get_pkgconfig_vars(opkg => "ganglia", context => "",
#                      name => "gmond_if");
# The arguments "name" and "context" are optional.
#
sub get_pkgconfig_vars {
    my (%sel) = @_;
    croak("opkg not specified!")	if (!exists($sel{opkg}));
    if (!exists($sel{context}) || $sel{context} eq "") {
	$sel{context} = "global";
    }
    my (%options, @errors);
    my $opkg = $sel{opkg};
    delete $sel{opkg};
    my $sql = "SELECT Packages.package AS opkg, " .
       	"Packages_config.config_id AS config_id, " .
       	"Packages_config.package_id AS package_id, " .
	"Packages_config.name AS name, " .
	"Packages_config.value AS value, " .
	"Packages_config.context AS context ".
	"FROM Packages_config, Packages " .
	"WHERE Packages_config.package_id=Packages.id AND ".
	"Packages.package='$opkg' AND ";
    my @where = map { "Packages_config.$_='".$sel{$_}."'" } keys(%sel);
    $sql .= join(" AND ", @where);
    my @result = ();
    die "$0:Failed to query values via << $sql >>"
        if (!do_select($sql,\@result, \%options, \@errors));

    return @result;
}

# convert pkgconfig vars query result into a values hash tree
# good to be used with the configurator routines
sub pkgconfig_values {
    my (@result) = @_;
    my %values;
    for my $r (@result) {
	my $name = $r->{name};
	my $val  = $r->{value};
	if (!exists($values{$name})) {
	    $values{"$name"} = [ "$val" ];
	} else {
	    push @{$values{"$name"}}, "$val";
	}
    }
    return %values;
}

# delete package configuration values
# Usage example:
#   del_pkgconfig_vars(opkg => "ganglia", context => "",
#                      name => "gmond_if");
# At least the "opkg" selection must be specified!
# The arguments "name" and "context" are optional.
sub del_pkgconfig_vars {
    my (%sel) = @_;
    croak("opkg not specified!")	if (!exists($sel{opkg}));
    if (!exists($sel{context}) || $sel{context} eq "") {
	$sel{context} = "global";
    }
    my (%options, @errors);

    my @exists = &get_pkgconfig_vars(%sel);
    return 1 if (!scalar(@exists));

    for my $e (@exists) {
	my $id = $e->{config_id};

	my $sql = "DELETE FROM Packages_config WHERE config_id='$id'";
	my @result;
	die "$0:Failed to delete values via << $sql >>"
	    if (!do_update($sql,\@result, \%options, \@errors));
    }
    return 1;
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
                            "run-configurator",
                            "install-bin-pkgs",
                            "run-script-post-image",
                            "run-script-post-clients",
                            "run-script-post-install",
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

# Set the Wizard status with a new value
sub set_wizard_status {
    my ($step_name, $options_ref, $error_strings_ref) = @_;
    my $sql = "UPDATE Wizard_status SET status='normal' WHERE
    step_name='$step_name'";
    return do_update($sql,"Wizard_status",$options_ref,$error_strings_ref);
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
#    unlock($options_ref, $error_strings_ref);
    if ( defined $passed_errors_ref && ! ref($passed_errors_ref) && $passed_errors_ref ) {
    warn shift @$error_strings_ref while @$error_strings_ref;
    }
    
    return $success;
}

1;
