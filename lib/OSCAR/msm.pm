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
use OSCAR::Utils qw ( is_element_in_array );

our @EXPORT = qw( 
    describe_set
    machine_type
    list_clients_in_group
    list_machines
    list_machines_in_group
    list_servers_in_group
    list_sets
    use_file);

our $xml = new XML::Simple;  # XML parser object
our %list;

my $verbose = 0;

use_file("defaultms.xml");

################################################################################
#                                                                              #
#                               PUBLIC FUNCTIONS                               #
#                                                                              #
################################################################################



################################################################################
# Get the list of servers for a given group of nodes. For that we get first    #
# the list of all servers in the global list and then we select the nodes that #
# are both in that list and in the list of nodes present in the given group.   #
#                                                                              #
# Input: group, name of group for which we want the list of servers.           #
# Ouput: array with the list of servers' name.                                 #
################################################################################
sub list_servers_in_group {
    my $group = shift;
    my @group_servers = ();

    my @machines = list_machines_in_group ($group);
    print "List of machines in set $group: " if $verbose;
    print_array (@machines) if $verbose;
    my @servers = list_servers ();
    print "List of servers: " if $verbose;
    print_array (@servers) if $verbose;
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
    print "List of machines in set $group: " if $verbose;
    print_array (@machines) if $verbose;
    my @clients = list_clients ();
    print "List of clients: " if $verbose;
    print_array (@clients) if $verbose;
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

	if(system("xmlstarlet --version >/dev/null 2>&1") == 0) {
		my $rc = system("xmlstarlet val -s $schema_dir/machineset.xsd $machine_set_dir/$filename >/dev/null");
		if($rc != 0) {
			return "XML does not validate against schema\n";
		}
	} else {
		print "XML not validated: xmlstarlet not installed.\n";
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

