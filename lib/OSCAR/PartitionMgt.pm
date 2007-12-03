package OSCAR::PartitionMgt;

#
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
#
#   $Id: PartitionMgt.pm 4833 2006-05-24 08:22:59Z bli $
#
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
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# This package provides a set of function for the management of cluster 
# partitions.
#

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Utils;
use OSCAR::Database_generic qw (
                                do_insert
                                do_select
                               );
use OSCAR::Database qw (
                        oda_query_single_result
                        set_node_with_group
                        simple_oda_query
                       );
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            get_list_nodes_partition
            get_list_partitions
            oda_create_new_partition
            get_list_nodes_partition
            );

my $verbose = 1;

################################################################################
# Return the list of nodes (their names) that compose a cluster partition.     #
#                                                                              #
# Input: partition name, note that we assume the partition name is unique.     #
# Return: array of string, each element is a node name of a partition node.    #
#                                                                              #
# TODO: check if we really assume a partition name is unique or not.           #
################################################################################
sub get_list_nodes_partition ($) {
    my $partition_name = shift;

    # First we get the partition ID
    my $sql = "SELECT * FROM Partitions WHERE name='$partition_name'";
    my $partition_id = oda_query_single_result ($sql, "partition_id");

    # Then based on the partition ID, we can get the list of nodes associated
    # to this partition (node ids).
    $sql = "SELECT * From Partition_Nodes WHERE partition_id='$partition_id'";
    my @nodes_id = simple_oda_query ($sql, "node_id");

    # Finally for each node ID we find the node name
    my @nodes;
    foreach my $id (@nodes_id) {
        $sql = "SELECT * From Nodes WHERE id='$id'";
        my $n = oda_query_single_result ($sql, "name");
        push (@nodes, $n);
    }

    return @nodes;
}

################################################################################
# Get the list of partitions for a given cluster.                              #
#                                                                              #
# Input: cluster id.                                                           #
# Output: array with the list of partitions' id, return undef if no partition  #
#         is found.                                                            #
################################################################################
sub get_list_partitions ($) {
    my $cluster_id = shift;

    my $sql = "SELECT * FROM Cluster_Partitions WHERE cluster_id='$cluster_id'";
    my @partitions_id = simple_oda_query ($sql, "partition_id");

    my @partitions = ();
    foreach my $partition (@partitions_id) {
        my $sql2 = "SELECT * FROM Partitions WHERE partition_id='$partition'";
        my $partition_name = oda_query_single_result ($sql2, "name");
        push (@partitions, $partition_name);
    }

    if (scalar(@partitions) == 0) {
        return undef;
    } else {
        return (@partitions);
    }
}

################################################################################
# Populate the database about a new partition based on information about a set #
# of nodes.                                                                    #
# Input: - cluster_id,  Cluster identifier (integer).                          #
#        - group,       Name of the group of node.                             #
#        - server,      Reference to the array with the list of servers' name  #
#                       within the group.                                      #
#        - client,      Reference to the array with the list of clients' name  #
#                       within the group.                                      #
# Output: None.                                                                #
################################################################################
sub oda_create_new_partition {
    my ($cluster_name, $group, $servers, $clients) = @_;

    # TODO: we should deal with the cluster ID here!!!
    my $cluster_id = 1;

    if ($verbose) {
        print "\n\n++++++++++++ ODA: Creating a new partition ++++++++++++\n";
        print "Group: $group\n";
        print "List of servers: ";
        print_array (@$servers);
        print "List of clients: ";
        print_array (@$clients);
    }
    # We first check if the partition already exists
    my @config;
    die ("ERROR: Impossible to query ODA") 
        if (get_partition_info ($cluster_id, $group, \@config) == 0);
    if (scalar (@config)) {
        print "The partition already exist...\n";
        print "\tdeleting the previous record...\n";
        delete_partition_info ($cluster_id, $group, $servers, $clients);
    }
    print "Adding the partition record...\n";
    set_partition_info ($cluster_id, $group, $servers, $clients);
    print "++++++++++++ ODA: New partition created +++++++++++++++\n\n" 
        if $verbose;
}

################################################################################
# Get partition information from the database.                                 #
#                                                                              #
# Input: cluster_id, cluster identifier.                                       #
#        group, group name (servers versus clients).                           #
#        result_ref, reference to an array with the list of partitions for the #
#                    cluster.                                                  #
# Return: 1 if success, 0 else.                                                #s
################################################################################
sub get_partition_info {
    my ($cluster_id, $group, $result_ref) = @_;
    my $sql = "SELECT * FROM Partitions WHERE name='$group'";
    my $options_ref;
    my $error_strings_ref;
    return do_select($sql, $result_ref, $options_ref, $error_strings_ref);
}

################################################################################
# Set partition information in the database.                                   #
#                                                                              #
# Input: cluster, cluster identifier.                                          #
#        group_name, group name (servers versus clients).                      #
#        servers, list of servers for the partition.                           #
#        cients, list of clients for the partition.                            #
################################################################################
sub set_partition_info {
    my ($cluster_id, $group_name, $servers, $clients) = @_;
    my $sql;
    my $options_ref;
    my $error_strings_ref;
    our $server_id;
    our $client_id;

    # Step 1: we populate the partition info with basic info.
    # TODO: we should use here insert_into_table.
    $sql = "INSERT INTO Partitions(name) VALUES ('$group_name')";
    die "ERROR: Failed to insert values via << $sql >>"
            if! do_insert($sql,"Partitions", $options_ref, $error_strings_ref);

    # Step 2: we populate the table Cluster_Partitions (relation between 
    # partitions and clusters).
    # TODO: we should use here insert_into_table.
    # First we get the partition_id
    $sql = "SELECT partition_id FROM Partitions WHERE ".
           "Partitions.name = '$group_name'";
    my $partition_id = oda_query_single_result ($sql, "partition_id");

    $sql = "INSERT INTO Cluster_Partitions (cluster_id, partition_id) VALUES ".
           "('$cluster_id', '$partition_id')";
    die "ERROR: Failed to insert values via << $sql >>"
            if! do_insert($sql,
                          "Cluster_Partitions", 
                          $options_ref, 
                          $error_strings_ref);

    # Step 3: we populate the table Partition_nodes (relation between modes and
    # partitions).
    # WARNING: remember that a node can current have only one type: server or
    # client. It is NOT possible to define different types between group of 
    # nodes for a single node

    # We get the ODA id for servers (need in order to populate the database)
    my $sql = "SELECT id FROM Groups WHERE name='oscar_server'";
    my $server_id = oda_query_single_result ($sql, "id");
    print "ODA Server Id: $server_id\n" if $verbose;

    # We get the ODA id for clients (need in order to populate the database)
    $sql = "SELECT id FROM Groups WHERE name='oscar_clients'";
    my $client_id = oda_query_single_result ($sql, "id");
    print "ODA client Id: $client_id\n" if $verbose;

    foreach my $server (@$servers) {
        set_node_to_partition ($partition_id, $server, $server_id);
    }

    foreach my $client (@$clients) {
        set_node_to_partition ($partition_id, $client, $client_id);
    }
}

################################################################################
# Assign in the database a node to a partition.                                #
#                                                                              #
# Input: partition_id, partition identifier.                                   #
#        node_name, node's name that has to be assigned to the partition.      #
#        node_type, node type ODA identitifer (type is server versus client).  #
# Return: None.                                                                #
################################################################################
sub set_node_to_partition {
    my ($partition_id, $node_name, $node_type) = @_;

    my $options_ref;
    my $error_strings_ref;

    # First we check that the node is already in the database.
    # If not, we inlcude it with basic info. Note that OPM is supposed to check
    # that all needed information are available for the installation of OPKGs.
    my $sql = "SELECT id FROM Nodes WHERE name='$node_name'";
    my @node_ids = simple_oda_query ($sql, "id");
    my $node_id;
    if ( !scalar(@node_ids) ) {
        print "The node is not in the database, we add it...\n" if $verbose;
        my %node_info = ('name' => $node_name, 'type' => $node_type);
        my @list_nodes = ();
        push (@list_nodes, \%node_info);
        oda_add_node (@list_nodes);
        $node_id = oda_query_single_result ($sql, "id");
    } elsif (scalar(@node_ids) != 1) {
        die "ERROR: We have more than one record (".scalar(@node_ids).
            ") about node $node_name in the database";
    } else {
        $node_id = $node_ids[0];
    }
    # Then we have all information to populate the database.
    $sql = "INSERT INTO Partition_Nodes (partition_id, node_id, node_type) ".
           "VALUES ('$partition_id', '$node_id', '$node_type')";
    die "ERROR: Failed to insert values via << $sql >>"
        if! do_insert($sql,
                      "Partition_Nodes",
                      $options_ref,
                      $error_strings_ref);
}

################################################################################
# Add a given list of nodes to the database.                                   #
#                                                                              #
# TODO: the cluster name is still hardcoded.                                   #
#                                                                              #
# Input: node_list, array with the list of nodes name.                         #
# Return: None.                                                                #
################################################################################
sub oda_add_node (@) {
    my @node_list = @_;

    print "\n+++++ Adding nodes to the database +++++\n" if $verbose;
    foreach my $node (@node_list) {
        print "\tNode name: $node->{'name'}\n" if $verbose;
        print "\tNode type: $node->{'type'}\n" if $verbose;
        # We need at list the name of the node and its type
        if (!defined ($node->{'name'}) || !defined ($node->{'type'})) {
            die "ERROR: Impossible to get enough information about the node. ".
                "We cannot add it into the database.";
        }
        my %options;
        my @error_string = ();

        my $sql = "SELECT name FROM Groups WHERE id='$node->{'type'}'";
        my $type = oda_query_single_result ($sql, "name");
        set_node_with_group ($node->{'name'},
                             $type,
                             \%options,
                             \@error_string,
                             "oscar");
    }
    print "+++++ Nodes added to the database +++++\n\n" if $verbose;
}

################################################################################
# Delete a cluster partition from the database.                                #
#                                                                              #
# TODO: finish the code!!!!                                                    #
#                                                                              #
# Input: cluster_id, cluster identifier.                                       #
#        group_name, server versus client.                                     #
#        servers, list of servers name (array).                                #
#        clients, list of clients name (array).                                #
################################################################################
sub delete_partition_info {
    my ($cluster_id, $group_name, $servers, $clients) = @_;
    my $sql;
    my $options_ref;
    my $error_strings_ref;

    # Step 1: we populate the table Partition_nodes (relation between modes and
    # partitions).


    # Step 2: we populate the table Cluster_Partitions (relation between 
    # partitions and clusters).


    # Step 3: we populate the partition info with basic info.
    $sql = "DELETE FROM Partitions WHERE name = '$group_name'";
    die "ERROR: Failed to delete partition info via << $sql >>"
            if! oda::do_sql_command($options_ref, $sql,"DELETE Table Partitions", "", $error_strings_ref);

}