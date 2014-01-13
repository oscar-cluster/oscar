package OSCAR::osm;

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
#   Copyright (c) 2007 Oak Ridge National Laboratory
#                      All rights reserved
#
#   $Id$

use strict;

use vars qw(@EXPORT);
use base qw(Exporter);
#use lib ".", "$ENV{OSCAR_HOME}/lib";
our @EXPORT = qw(
                add_set
                add_opkg
                convert_hash_to_oda
                osm_array2hash
                osm_update_oda
                result
                );

use OSCAR::Env;
use OSCAR::psm;
use OSCAR::msm;
use OSCAR::Database qw (
                        update_node_package_status_hash
                        update_image_package_status
                       );
use OSCAR::Utils qw (print_array);
use Data::Dumper;

our %data;

#########################################################################
# Subroutine : add_set                                                  #
# Adds a set of packages specified in the passed in filename to the     #
# machines in the specified set. If there is no machine set specified,  #
# the packages will be added onto all machines.                         #
# Parameters : $pkgset_filename - The name of the file with the package #
#                 set in it relative to trunk/share/package_sets        #
#              $machineset (Optional) - The name of the machine set the #
#                 packages will be installed on                         #
# Returns    : A string saying either OK or giving an error message.    #
#########################################################################
sub add_set {
	our %data;
	my $pkgset = shift;
	my $machineset = shift;
	
	my @machines;
	
	if ($machineset) {
		@machines = describe_set($machineset);
	} else {
		@machines = list_machines();
	}
	
	# Push the name of the package set onto the list of sets
	# The sets will be combined later
	for my $machine (@machines) {
		push(@{$data{$machine}{sets}}, $pkgset);
	}
	
    if ($OSCAR::Env::oscar_verbose) {
        print "Number of elements in the hash: " . scalar (%data) . "\n";
        Dump (%data);
    }
	return 'OK';
}

#########################################################################
# Subroutine : add_opkg                                                 #
# Adds a package specified to the machines in the specified set. If     #
# there is no machine set specified, the packages will be added onto all#
# machines.                                                             #
# Parameters : $opkg - The name of the OPKG                             #
#              $machineset (Optional) - The name of the machine set the #
#                 packages will be installed on                         #
# Returns    : A string saying either OK or giving an error message.    #
#########################################################################
sub add_opkg {
	our %data;
	my $opkg = shift;
	my $machineset = shift;
	
	my @machines;
	
	if ($machineset) {
		@machines = describe_set($machineset);
	} else {
		@machines = list_machines();
	}
	
	# Push the name of the package onto the list of packages
	# Later it will be combined with the sets
	for my $machine (@machines) {
		push(@{$data{$machine}{packages}}, $opkg);
	}
	
	return 'OK';
}

#########################################################################
# Subroutine : result                                                   #
# Returns the result of the additions in a single hash which can be     #
# passed into a tool to actually install the packages.                  #
# Parameters : None                                                     #
# Returns    : A hash containing all the installation information       #
#########################################################################
sub result {
	our %data;
	
	# Loop over all machines
	for my $machine (keys(%data)) {
		clear_list();
		
		# Loop over all package sets
		for my $pkgset (@{$data{$machine}{sets}}) {	
			my $ret = select_set($pkgset);
			
			if ($ret ne 'OK') {die $ret;}
		}
		
		for my $opkg (@{$data{$machine}{packages}}) {
			my $ret = select_opkg($opkg);
			
			if ($ret ne 'OK') {die $ret;}
		}
		
		%{$data{$machine}{spec}} = package_hash();
	}
	
	return %data;
}

#########################################################################
# Subroutine : use_machine_file                                         #
# Tells the machine set manager to use a different file than the default#
# one to define the machine sets.  The filename should be relative to   #
# trunk/share/machine_sets, which is the directory where all machine    #
# set files should be located.                                          #
# Parameters : $filename - The filename of the machine set              #
# Returns    : A scalar variable containing an error message if there   #
#              is an error                                              #
#########################################################################
sub use_machine_file {
	my $filename = shift;
	
	return use_file($filename);
}

#########################################################################
# Subroutine : setup_hash                                               #
# Sets up the structure of the hash so it matches the machine file      #
# already loaded by the use_machine_file method.  Makes a key for each  #
# machine in the file.                                                  #
# Parameters : None                                                     #
# Returns    : None                                                     #
#########################################################################
sub setup_hash {
	our %data;

	my @machines = list_machines();

	for my $machine (@machines) {
		$data{$machine} = (sets => [], packages => []);
	}

}

################################################################################
# Subroutine: convert_hash_to_oda                                              #
# This module is for converting the hash that comes out of OSM into database   #
# form for OPM.                                                                #
# TODO -  Use version restrictions stored in the hash                          #
#           There are also other pieces of info not used (distro, arch, lists  #
#               of packages and sets selected). These can be saved or          #
#               discarded.                                                     #
# Parameter: hash representing the mackage/machine set.                        #
# Return   : None.                                                             #
################################################################################
sub convert_hash_to_oda {
#    my %data = %{$_[0]};
    my %data = shift;
    my @opkg_to_install = OSCAR::psm::show_list();
    print "The package sets includes: ";
    print_array (@opkg_to_install);

    # Go through each node in the hash
    for my $nodename (keys(%data)) {

        # Go through each package for the node
         foreach my $package ($data{$nodename}{package}) {
             print "Node name = $nodename\n";
            print "Package name = $package\n";
 
             # Set the package's requested values to 'finished'
             my %options;
             my @errors;
             my %field_values;
             $field_values{requested} = 'finished';
             update_node_package_status_hash(\%options, $nodename, $package, 
                     \%field_values, \@errors);
         }
    }
}

################################################################################
# This function only translates a simple array with the list of OPKG to        #
# install into a has with more information, information needed by ODA.         #
# Input: list, array with the OPKGs to install.                                #
# Output: data, hash with the OPKG to install and the associated status. This  #
#               hash can then be used to update the database.                  #
################################################################################
sub osm_array2hash {
    my ($value, @opkgs) = @_;
    my %data;

    foreach my $opkg (@opkgs) {
        # We find the Package id based on the package name
#         my $pkg_id = find_package_id_from_name ($opkg);
        $data{$opkg} = $value;
    }

    return %data;
}

################################################################################
# This function update information about a given image. For instance it is     #
# used to store information about OPKGs that have to be installed.             #
# Input: hash, information about OPKGs (name + value of OPKG's satutus to      #
#              store.                                                          #
# Return: None.                                                                #
################################################################################
sub update_image_data {
    my %data;
    my %options = ();
    my @errors = ();
    my $OSCAR_SERVER_NODE = "oscar_server";
    my $success;

    while ((my $package_name, my $value) = each(%data)) {
        # installable tag is kept on config.xml and this is an easier way
        # to avoid tracing not-installable packages (e.g., networking).
        $success = update_image_package_status(
                        \%options,
                        $OSCAR_SERVER_NODE,
                        $package_name,
                        $value,
                        \@errors);
    }
}

################################################################################
# Update ODA based on a table ID. This function is typically used to update    #
# information about OPKG for images and compute nodes.                         #
# Input: table_id, the table identifier in ODA that needs to be update         #
#                  (e.g. Image_Package_Status).                                #
#        data, hash grabbing all the information to update, i.e., db table     #
#              entry / new value.                                              #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub osm_update_oda {
    my ($table_id, %data) = @_;

    if ($OSCAR::Env::oscar_verbose) {
        print "Data to update: \n";
        while ((my $key, my $value) = each(%data)) {
            print $key.", ".$value."\n";
        }
    }

    if ($table_id eq "Image_Package_Status") {
        update_image_data (%data);
    }
}


1;
