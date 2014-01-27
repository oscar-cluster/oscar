package OSCAR::msm;

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
#                      Wesley Bland <blandwb@ornl.gov>
#                      Geoffroy Vallee <valleegr@ornl.gov>
#                      All rights reserved
#
#   $Id$

use strict;

use vars qw(@EXPORT);
use base qw(Exporter);
use lib ".", "$ENV{OSCAR_HOME}/lib";
use XML::Simple;	# Read the XML package set files
use Data::Dumper;
use OSCAR::Env;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::Utils qw ( 
                    print_array
                    is_element_in_array 
                    oscar_system
                    );
use OSCAR::PartitionMgt qw  (
                            oda_create_new_partition 
                            );

our @EXPORT = qw( 
                add_partition
                describe_set
                list_clients_in_group
                list_machines
                list_machines_in_group
                list_servers_in_group
                list_sets
                machine_type
                parse_machine_set
                use_file);

our $xml = new XML::Simple;  # XML parser object
our %list;

#my $verbose = 0;

use_file("defaultms.xml");

################################################################################
#                                                                              #
#                               PUBLIC FUNCTIONS                               #
#                                                                              #
################################################################################

################################################################################
# Populate the database for the creation of a new cluster.                     #
# Note that we currently support only one cluster with multiple partitions.    #
#                                                                              #
# Inpt: partition_name, name of the partition to add;                          #
#       distro, Linux distribution ID (OS_Detect syntax) that has to be used   #
#               on the partition.                                              #s
#       clients, reference to an array representing the list of clients name   #
#                (for instance [oscarnode1, oscarnode2, oscarnode3]).          #
# Return: returns ODA error code.                                              #
#                                                                              #
# TODO: - support multiple clusters, we currently assume we have a single      #
#         cluster, named "oscar".                                              #
#       - support multiple servers, we currently assume we have a single       #
#         headnode (beowulf architecture).                                     #
################################################################################
sub add_partition ($$$$) {
    my ($cluster_name, $partition_name, $distro, $list_clients) = @_;
    my $ret = oda_create_new_partition ($cluster_name, 
                                        $partition_name,
                                        $distro,
                                        undef,
                                        $list_clients);
    return $ret;
}

################################################################################
# Get the list of servers for a given group of nodes. For that we get first    #
# the list of all servers in the global list and then we select the nodes that #
# are both in that list and in the list of nodes present in the given group.   #
#                                                                              #
# Input: group, name of group for which we want the list of servers.           #
# Ouput: array with the list of servers' name.                                 #
################################################################################
sub list_servers_in_group ($) {
    my $group = shift;
    my @group_servers = ();

    my @machines = list_machines_in_group ($group);
    oscar_log(6, INFO, "List of machines in set $group:");
    print_array (@machines) if( $OSCAR::Env::oscar_verbose >= 5);
    my @servers = list_servers ();
    oscar_log(6, INFO, "List of servers:");
    print_array (@servers) if( $OSCAR::Env::oscar_verbose >= 5);
    foreach my $node (@machines) {
        if (is_element_in_array ($node, @servers)) {
            push (@group_servers, $node);
        }
    }
    return @group_servers;
}


################################################################################
# Get the list of compute nodes (clients) for a given group of nodes. For that #
# we get first the list of all clients in the global list and then we select   #
# the nodes that are both in that list and in the list of nodes present in the #
# given group.                                                                 #
#                                                                              #
# Input: group, name of group for which we want the list of compute nodes.     #
# Ouput: array with the list of compute nodes' name.                           #
################################################################################
sub list_clients_in_group {
    my $group = shift;
    my @group_clients = ();

    my @machines = list_machines_in_group ($group);
    oscar_log(6, INFO, "List of machines in set $group:");
    print_array (@machines) if($OSCAR::Env::oscar_verbose >= 5);
    my @clients = list_clients ();
    oscar_log(6, INFO, "List of clients:");
    print_array (@clients) if($OSCAR::Env::oscar_verbose >= 5);
    foreach my $node (@machines) {
        if (is_element_in_array ($node, @clients)) {
            push (@group_clients, $node);
        }
    }

    return @group_clients;
}

#########################################################################
# Subroutine : use_file                                                 #
# Use a different file for the machine sets than the default file       #
# Parameters : The name of a machine set file                           #
# Returns    : An error message if the file does not exist              #
#########################################################################
sub use_file {
	our %list;
	my $filename = shift;
    my $schema_dir = "$ENV{OSCAR_HOME}/share/schemas";
    my $machine_set_dir = "$ENV{OSCAR_HOME}/share/machine_sets";
	
	# Make sure the file is there
	
	unless (-f "$machine_set_dir/$filename") {
		return "File $machine_set_dir/$filename not found";
	}
	
	# Check to see if the xml validates against the schema

    my $cmd = "xmlstarlet --version >/dev/null 2>&1";
	if(oscar_system($cmd) == 0) {
        $cmd = "xmlstarlet val -s $schema_dir/machineset.xsd $machine_set_dir/$filename >/dev/null";
		my $rc = oscar_system($cmd);
		if($rc != 0) {
			return "XML does not validate against schema\n";
		}
	} else {
		oscar_log(5, ERROR, "XML not validated: xmlstarlet not installed.");
	}
	
	%list = %{$xml->XMLin("$machine_set_dir/$filename", ForceArray => ['machine', 'machineSet'])};
    return undef;
}

#########################################################################
# Subroutine : describe_set                                             #
# Lists the names of all the machines in the specified machine set      #
# Parameters : The name of a machine set                                #
# Returns    : A list of the machine names in the set                   #
#########################################################################
sub describe_set {
	our %list;
	my $set_name = shift;
	
	return @{$list{machineSet}{$set_name}{hostname}};
}

#########################################################################
# Subroutine : list_sets                                                #
# Lists the names of all the machine sets in the machine sets file      #
# Parameters : None                                                     #
# Returns    : A list of the machine set names                          #
#########################################################################
sub list_sets {
    our %list;
    my @list = ();
    
    foreach my $key (keys %{$list{machineSet}}) {
        push (@list, $key);
    }

    return @list;
}

#########################################################################
# Subroutine : machine_type                                             #
# Gives the type of a specified machine                                 #
# Parameters : The hostname of the machine                              #
# Returns    : The type of the machine                                  #
#########################################################################
sub machine_type {
	our %list;
	my $hostname = shift;
	
	for my $h (@{$list{machine}}) {
		if($$h{hostname} eq $hostname) {
			return $$h{nodeType};
		}
	}
}

#########################################################################
# Subroutine : list_machines                                            #
# Lists the names of all the machine in the machine sets file           #
# Parameters : None                                                     #
# Returns    : A list of the machine names                              #
#########################################################################
sub list_machines {
	our %list;
	
	my @hostnames;
	for my $h (@{$list{machine}}) {
		push (@hostnames, $$h{hostname});
	}
	
	return @hostnames;
}

#########################################################################
# Subroutine : list_machines_in_group                                   #
# Lists the names of all the machine in a given group of nodes.         #
# Parameters : group, group name.                                       #
# Returns    : A list of the machine names                              #
#########################################################################
sub list_machines_in_group {
    my $group = shift;
    our %list;

    return @{$list{machineSet}{$group}{hostname}}
}

################################################################################
#                                                                              #
#                               PRIVATE FUNCTIONS                              #
#                                                                              #
################################################################################

################################################################################
# Get the overall list of servers based on the machine set (i.e., servers from #
# all the defined group of nodes).                                             #
#                                                                              #
# Input: None.                                                                 #
# Output: array with the name of all the servers.                              #
################################################################################
sub list_servers {
    our %list;
    my @list_servers = ();

    for my $k (@{$list{machine}}) {
        if ($$k{nodeType} eq "server") {
            push (@list_servers, $$k{hostname});
        }
    }
    return @list_servers;
}

################################################################################
# Get the overall list of clients based on the machine set (i.e., clients from #
# all the defined group of nodes).                                             #
#                                                                              #
# Input: None.                                                                 #
# Output: array with the name of all the clients.                              #
################################################################################
sub list_clients {
    our %list;
    my @list_clients = ();

    for my $k (@{$list{machine}}) {
        if ($$k{nodeType} eq "client") {
            push (@list_clients, $$k{hostname});
        }
    }
    return @list_clients;
}

################################################################################
# Parse the XML file describing machine set(s). Based on the XML file the      #
# database is populated, with will then be used by OPM.                        #
#                                                                              #
# Input: path of the XML file (relative to $OSCAR_HOME/share/machine_sets).    #
# Return: None.                                                                #
#                                                                              #
# TODO: currently we support only one cluster, named "oscar". We should extend #
#       the cluster management to multiple clusters.                           #
################################################################################
sub parse_machine_set ($) {
    my $xml_file_path = shift;

    # Step 1: We use OSM to parse the XML file
    oscar_log(6, INFO, "Parsing the machine set...");
    my $res = OSCAR::msm::use_file ($xml_file_path);
    die $res if defined $res;

    # Step 2: We get the list of machine sets
    my @list_sets = OSCAR::msm::list_sets();
    oscar_log(6, INFO, "Machine set(s):");
    print_array @list_sets if($OSCAR::Env::oscar_verbose >= 5);

    # Step 3: for each set we get the list of servers and compute nodes and we 
    # populate the database accordingly.

    foreach my $group (@list_sets) {
        # We get the list of servers for the current group of nodes
        my @group_servers = list_servers_in_group ($group);
        oscar_log(6, INFO, "List of servers in group $group:");
        print_array (@group_servers) if($OSCAR::Env::oscar_verbose >= 5);

        # We get the list of clients for the current group of nodes
        my @group_clients = list_clients_in_group ($group);
        oscar_log(6, INFO, "List of clients in group $group:");
        print_array (@group_clients) if($OSCAR::Env::oscar_verbose >= 5);

        # Now we populate the database: each machine group is a partition.
        my @partition_config = ( @group_servers, @group_clients );
        oda_create_new_partition ("oscar",
                                $group,
                                "",
                                \@group_servers, 
                                \@group_clients);
    }
    
    return (@list_sets);
}
