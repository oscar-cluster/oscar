package OSCAR::PartitionMgt;

#
# Copyright (c) 2007-2008 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
#
#   $Id$
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

# TODO: we should be able to simplify a little the API of this module.

use strict;
use File::Path;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Utils;
use OSCAR::FileUtils;
use OSCAR::Database_generic qw (
                                do_insert
                                do_select
                               );
use OSCAR::Database qw (
                        oda_query_single_result
                        set_node_with_group
                        simple_oda_query
                       );
use OSCAR::Logger;
use OSCAR::ConfigManager;
use OSCAR::ImageMgt;
use OSCAR::MAC;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;
use warnings "all";

@EXPORT = qw(
            deploy_partition
            display_partition_info
            get_list_nodes_partition
            get_list_partitions
            get_partition_distro
            display_partition_info
            oda_create_new_partition
            validate_partition_data
            );

my $verbose = 1;

################################################################################
# Return the Linux distribution ID (OS_Detect syntax) associated to the        #
# partitions.                                                                  #
# DEPRECATED: We should use a display_partition_info like function instead.    #
#                                                                              #
# Input: partition name, note that we assume the partition name is unique.     #
# Return: string representing the distro ID (OS_Detect syntax).                #
################################################################################
sub get_partition_distro ($$) {
    my ($cluster_name, $partition_name) = @_;

    # Some basic checking...
    if (!defined ($cluster_name)
        || $cluster_name eq "") {
        carp "ERROR: invalid cluster name ($cluster_name)\n";
        return undef;
    }
    if (!defined ($partition_name)
        || $partition_name eq "") {
        carp "ERROR: invalid partition name ($partition_name)\n";
        return undef;
    }

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return undef;
    }
    my $config = $oscar_configurator->get_config();

    my $distro;
    if ($config->{db_type} eq "db") {
        my $sql = "SELECT * FROM Partitions WHERE name='$partition_name'";
        $distro = oda_query_single_result ($sql, "distro");
    } elsif ($config->{db_type} eq "file") {
        # We get the path of the partition configuration file.
        my $f = $oscar_configurator->get_partition_config_file_path (
                    $cluster_name,
                    $partition_name);
        $f .= "/$partition_name.conf";
        # we create an object for the manipulation of the partition config file.
        require OSCAR::PartitionConfigManager;
        my $config_obj = OSCAR::PartitionConfigManager->new(
            config_file => "$f");
        if ( ! defined ($config_obj) ) {
            carp "ERROR: Impossible to create an object in order to handle ".
                 "the partition configuration file.\n";
            return -1;
        }
        my $partition_config = $config_obj->get_config();
        if (!defined ($partition_config)) {
            carp "ERROR: Impossible to load the partition configuration file\n";
            return undef;
        }
        my $id = $partition_config->{'distro'}.
                 "-".
                 $partition_config->{'distro_version'}.
                 "-".
                 $partition_config->{'arch'};
        return $id;
    } else {
        carp "ERROR: Unknown ODA type ($config->{db_type})\n";
        return undef;
    }
    return $distro;
}

################################################################################
# Return the list of nodes (their names) that compose a cluster partition.     #
#                                                                              #
# Input: partition name, note that we assume the partition name is unique.     #
# Return: array of string, each element is a node name of a partition node;    #
#         undef if error.
#                                                                              #
# TODO: check if we really assume a partition name is unique or not.           #
################################################################################
sub get_list_nodes_partition ($$) {
    my ($cluster_name, $partition_name) = @_;
    my @nodes;

    # Some basic checking...
    if (!defined ($cluster_name)
        || $cluster_name eq "") {
        carp "ERROR: invalid cluster name ($cluster_name)\n";
        return undef;
    }
    if (!defined ($partition_name) 
        || $partition_name eq "") { 
        carp "ERROR: invalid partition name ($partition_name)\n";
        return undef;
    }

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return undef;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "db") {
        # First we get the partition ID
        my $sql = "SELECT * FROM Partitions WHERE name='$partition_name'";
        my $partition_id = oda_query_single_result ($sql, "partition_id");

        # Then based on the partition ID, we can get the list of nodes associated
        # to this partition (node ids).
        $sql = "SELECT * From Partition_Nodes WHERE partition_id='$partition_id'";
        my @nodes_id = simple_oda_query ($sql, "node_id");

        # Finally for each node ID we find the node name
        foreach my $id (@nodes_id) {
            $sql = "SELECT * From Nodes WHERE id='$id'";
            my $n = oda_query_single_result ($sql, "name");
            push (@nodes, $n);
        }
    } elsif ($config->{db_type} eq "file") {
        my $path = $oscar_configurator->get_partition_config_file_path (
            $cluster_name,
            $partition_name);
        # Some basic checking...
        if (!defined ($path) || ! -d "$path") {
            carp "ERROR: Partition $partition_name does not exist\n";
            return undef;
        }
        @nodes = OSCAR::FileUtils::get_dirs_in_path ("$path");
    } else {
        carp "ERROR: Unknown ODA type ($config->{db_type}).\n";
        return undef;
    }

    return @nodes;
}

################################################################################
# Get the list of partitions for a given cluster, based on his id.             #
#                                                                              #
# Input: cluster id.                                                           #
# Output: array with the list of partitions' id, return undef if no partition  #
#         is found.                                                            #
################################################################################
sub get_list_partitions_from_clusterid ($) {
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
# Get the list of partitions for a given cluster, based on his id.             #
#                                                                              #
# Input: cluster name.                                                         #
# Return: array with the list of partitions name or undef if error.            #
################################################################################
sub get_list_partitions ($) {
    my $cluster_name = shift;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    my @partitions;
    if ($config->{db_type} eq "db") {
        my $sql = "SELECT * FROM Clusters WHERE name='$cluster_name'";
        my $cluster_id = OSCAR::Database::oda_query_single_result ($sql, "id");
#        @partitions = get_list_partitions ($cluster_id);
    } elsif ($config->{db_type} eq "file") {
        my $path =
            $oscar_configurator->get_cluster_config_file_path($cluster_name);
        if ( ! -d "$path" ) {
            carp "ERROR: cluster $cluster_name does not exist\n";
            return undef;
        }
        @partitions 
            = OSCAR::FileUtils::get_dirs_in_path ("$path");
    } else {
        carp "ERROR: unknown ODA type ($config->{db_type})";
        return undef;
    }

    return @partitions;
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
sub oda_create_new_partition ($$$$$) {
    my ($cluster_name, $partition_name, $distro, $servers, $clients) = @_;

    if ($verbose) {
        oscar_log_section "ODA: Creating a new partition";
        oscar_log_subsection "Cluster: $cluster_name";
        oscar_log_subsection "Partition: $partition_name";
        oscar_log_subsection "List of servers: ";
        print_array (@$servers);
        oscar_log_subsection "List of clients: ";
        print_array (@$clients);
    }

    # We first check if the partition already exists
    my @config = get_partition_info ($cluster_name, $partition_name);
    if (!@config) {
        carp "ERROR: Impossible to query ODA";
        return -1;
    }
    if (scalar (@config)) {
        oscar_log_subsection "The partition already exist...";
        oscar_log_subsection "Deleting the previous record...";
        delete_partition_info ($cluster_name, $partition_name, $distro, 
                               $servers, $clients);
    } 
    oscar_log_subsection "Adding the partition record...";
    set_partition_info ($cluster_name,
                        $partition_name,
                        $distro,
                        $servers,
                        $clients);
    oscar_log_section "ODA: New partition created" if $verbose;

    return 0;
}

################################################################################
# Get partition information from the database.                                 #
#                                                                              #
# Input: cluster_id, cluster identifier.                                       #
#        group, group name (servers versus clients).                           #
#        result_ref, reference to an array with the list of partitions for the #
#                    cluster.                                                  #
# Return: array with the name of cluster partitions, undef if error.           #
#                                                                              #
# TODO: this function currently does not make sense.                           #
################################################################################
sub get_partition_info ($$) {
    my ($cluster_name, $partition_name) = @_;
    my @partitions;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "db") {
        # TODO: this current does not work
        carp "Sorry this cluster management cannot currently use a real ".
             "database, only a flat file based ODA version. Check our OSCAR ".
             "configuration file\n";
        my $sql = "SELECT * FROM Partitions WHERE name='$partition_name'";
        my $options_ref;
        my $error_strings_ref;
        my $result_ref;
        do_select($sql, $result_ref, $options_ref, $error_strings_ref);
    } elsif ($config->{db_type} eq "file") {
        my $path = $config->{oda_files_path};
        if ( ! -d "$path") {
            carp "ERROR: the cluster configuration directory does not exist ".
                 "($path). It most certainly mean that OSCAR is not correctly ".
                 "initialized\n";
            return undef;
        }

        # Step 1: Does the cluster exist?
        $path =
            $oscar_configurator->get_cluster_config_file_path($cluster_name);
        if ( ! -d "$path") {
            print "WARNING: Cluster does not exist ($cluster_name)\n";
            return undef;
        }

        # Step 2: Do partitions exist?
        @partitions =
            OSCAR::FileUtils::get_dirs_in_path ("$path");
    }
    print "Partitions:\n";
    print_array @partitions;
    return @partitions;
}


################################################################################
# Set partition information in the database.                                   #
#                                                                              #
# Input: cluster_name, cluster name.                                           #
#        group_name, group name (servers versus clients).                      #
#        servers, list of servers for the partition.                           #
#        cients, list of clients for the partition.                            #
# TODO: error handling.                                                        #
# TODO: the code for the real db is buggy.                                     #
################################################################################
sub set_partition_info {
    my ($cluster_name, $partition_name, $distro_id, $servers, $clients) = @_;
#    my $sql;
    my $options_ref;
    my $error_strings_ref;
    our $server_id;
    our $client_id;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "db") {
        my $sql;
        # Step 1: we populate the partition info with basic info.
        # TODO: we should use here insert_into_table.
#        $sql = "INSERT INTO Partitions(name, distro) VALUES ".
#               "('$group_name', '$distro')";
        die "ERROR: Failed to insert values via << $sql >>"
            if! do_insert($sql,"Partitions", $options_ref, $error_strings_ref);

        # Step 2: we populate the table Cluster_Partitions (relation between 
        # partitions and clusters).
        # TODO: we should use here insert_into_table.
        # First we get the partition_id
#        $sql = "SELECT partition_id FROM Partitions WHERE ".
#               "Partitions.name = '$group_name'";
        my $partition_id = oda_query_single_result ($sql, "partition_id");

#        $sql = "INSERT INTO Cluster_Partitions (cluster_id, partition_id) VALUES ".
#               "('$cluster_id', '$partition_id')";
        if (!do_insert($sql,
                       "Cluster_Partitions", 
                       $options_ref, 
                       $error_strings_ref)) {
            carp "ERROR: Failed to insert values via << $sql >>";
            return -1;
        }

        # Step 3: we populate the table Partition_nodes (relation between modes and
        # partitions).
        # WARNING: remember that a node can current have only one type: server or
        # client. It is NOT possible to define different types between group of 
        # nodes for a single node

        # We get the ODA id for servers (need in order to populate the database)
        $sql = "SELECT id FROM Groups WHERE name='oscar_server'";
        my $server_id = oda_query_single_result ($sql, "id");
        print "ODA Server Id: $server_id\n" if $verbose;

        # We get the ODA id for clients (need in order to populate the database)
        $sql = "SELECT id FROM Groups WHERE name='oscar_clients'";
        my $client_id = oda_query_single_result ($sql, "id");
        print "ODA client Id: $client_id\n" if $verbose;
    } elsif ($config->{db_type} eq "file") {
        my $basedir = $config->{oda_files_path};
        if ( ! -d "$basedir") {
            carp "ERROR: the cluster configuration directory does not exist ".
                 "($basedir). It most certainly mean that OSCAR is not ".
                 "correctly initialized\n";
            return -1;
        }

        # Step 1: Does the cluster exist?
        my $path = 
            $oscar_configurator->get_cluster_config_file_path ($cluster_name);
        if ( ! -d "$path") {
            mkdir "$path";
        }

        # Step 2: Does the partition already exist?
        # If so, we exist; if not we create it
        my $partitionPath = $oscar_configurator->get_partition_config_file_path(
                $cluster_name,
                $partition_name);
        if ( ! -d "$partitionPath") {
            mkdir "$partitionPath";
        }

        # Step 3: the FS has been updated to welcome the partition configuration
        # file.
        my ($distro, $distro_version, $arch) = split ("-", $distro_id);
        my %partition_config = (
                'distro'        => $distro,
                'distro_version' => $distro_version,
                'arch'          => $arch
                );
        my $config_file = "$partitionPath/$partition_name.conf";
        # We create an object for the manipulation of the partition config file.
        require OSCAR::PartitionConfigManager;
        my $config_obj = OSCAR::PartitionConfigManager->new(
            config_file => "$config_file");
        if ( ! defined ($config_obj) ) {
            carp "ERROR: Impossible to create an object in order to handle ".
                 "the partition configuration file.\n";
            return -1;
        }
        $config_obj->set_config(\%partition_config);
    }

    if (scalar (@$servers) > 0) {
        foreach my $server (@$servers) {
            set_node_to_partition ($cluster_name,
                                   $partition_name,
                                   $server,
                                   $server_id);
        }
    }

    if (scalar (@$clients) > 0) {
        foreach my $client (@$clients) {
            set_node_to_partition ($cluster_name,
                                   $partition_name,
                                   $client,
                                   $client_id);
        }
    }

    return 0;
}

################################################################################
# Assign in the database a node to a partition.                                #
#                                                                              #
# Input: cluster_name. cluster name.                                           #
#        partition_name, partition name.                                       #
#        node_name, node's name that has to be assigned to the partition.      #
#        node_type, node type ODA identitifer (type is server versus client).  #
# Return: 0 if success, -1 else.                                               #
# TODO: code for the real db is incomplete.                                    #
################################################################################
sub set_node_to_partition ($$$$) {
    my ($cluster_name, $partition_name, $node_name, $node_type) = @_;

    my $options_ref;
    my $error_strings_ref;

    # few asserts.
    return -1 if (!defined $cluster_name || $cluster_name eq "");
    return -1 if (!defined $partition_name || $partition_name eq "");
    # If the node name is not defined or empty we do nothing.
    return -1 if (!defined $node_name || $node_name eq "");

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($verbose) {
        oscar_log_section "Adding a node to a partition";
        oscar_log_subsection "Cluster name: $cluster_name";
        oscar_log_subsection "Partition name: $partition_name";
        oscar_log_subsection "Node name: $node_name";
    }

    if ($config->{db_type} eq "db") {
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
            carp "ERROR: We have more than one record (".scalar(@node_ids).
                 ") about node $node_name in the database";
            return -1;
        } else {
            $node_id = $node_ids[0];
        }
        # Then we have all information to populate the database.
#        $sql = "INSERT INTO Partition_Nodes (partition_id, node_id, node_type) ".
#               "VALUES ('$partition_id', '$node_id', '$node_type')";
        if (! do_insert($sql,
                        "Partition_Nodes",
                        $options_ref,
                        $error_strings_ref)) {
            carp "ERROR: Failed to insert values via << $sql >>";
            return -1;
        }
    } elsif ($config->{db_type} eq "file") {
        # Step1: does the directory for the node exist?
        # If not, we create it; if yes, this is an error.
        my $path = $oscar_configurator->get_node_config_file_path(
                       $cluster_name,
                       $partition_name,
                       $node_name);
        if ( -d $path ) {
            carp "ERROR: Impossible to add the node $node_name, the node is ".
                 "already defined\n";
            return -1;
        } else {
            mkdir $path;
        }
    } else {
        carp "ERROR: Unknow ODA type ($config->{db_type})";
        return -1;
    }
    return 0;
}

################################################################################
# Add a given list of nodes to the database.                                   #
#                                                                              #
# TODO: the cluster name is still hardcoded.                                   #
#                                                                              #
# Input: node_list, array with the list of nodes name.                         #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub oda_add_node (@) {
    my @node_list = @_;

    oscar_log_section "Adding nodes to the database" if $verbose;
    foreach my $node (@node_list) {
        oscar_log_subsection "\tNode name: $node->{'name'}" if $verbose;
        oscar_log_subsection "\tNode type: $node->{'type'}" if $verbose;
        # We need at list the name of the node and its type
        if (!defined ($node->{'name'}) || !defined ($node->{'type'})) {
            carp "ERROR: Impossible to get enough information about the node. ".
                 "We cannot add it into the database.";
            return -1;
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
    oscar_log_section "Nodes added to the database" if $verbose;
}

################################################################################
# Delete a cluster partition from the database.                                #
#                                                                              #
# TODO: Write the code for a real db.                                          #
#                                                                              #
# Input: cluster_name, cluster name.                                           #
#        partition_name, partition name.                                       #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub delete_partition_info {
    my ($cluster_name, $partition_name, $distro, $servers, $clients) = @_;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "db") {
        my $sql;
        my $options_ref;
        my $error_strings_ref;
#        $sql = "DELETE FROM Partitions WHERE name = '$group_name'";
        if (! oda::do_sql_command($options_ref, 
                                  $sql,
                                  "DELETE Table Partitions",
                                  "",
                                  $error_strings_ref)) {
            carp "ERROR: Failed to delete partition info via << $sql >>";
            return -1;
        }
    } elsif ($config->{db_type} eq "file") {
        my $basedir = $config->{oda_files_path};
        if ( ! -d "$basedir" ) {
            carp "ERROR: Configuration files missing, OSCAR is not correctly ".
                 "initialized\n";
            return -1;
        }
        my $path = $oscar_configurator->get_partition_config_file_path (
                        $cluster_name,
                        $partition_name);
        if ( ! -d "$path" ) {
            carp "Warning: the partition does not exist, no need to delete ".
                 "it\n";
            # This is not a error, if the partition does not exist, it means 
            # that the job is already done.
            return 0;
        } else {
            rmtree "$path";
        }
    } else {
        carp "ERROR: Unkown db type ($config->{db_type})\n";
        return -1;
    }
    return 0;
}

################################################################################
# Validate partition data, to be sure we have everything we need before to try #
# to deploy compute nodes.                                                     #
#                                                                              #
# Input: partition, name of the partition we have to validate.                 #
# Return: 0 if success, -1 else.                                               #
#                                                                              #
# TODO: implement a stronger checking mechanism. Current we only check the     #
#       minimum.                                                               #
################################################################################
sub validate_partition_data ($$) {
    my ($cluster, $partition) = @_;

    # If configuration files are not there, this is not normal
    require OSCAR::PartitionConfigManager;
    my $oconfig = OSCAR::ConfigManager->new();
    if ( ! defined ($oconfig) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $f = $oconfig->get_partition_config_file_path($cluster, $partition)
            ."/$partition.conf";
    if ( ! -f $f ) {
        carp "ERROR: Impossible to get the partition configuration file ".
             "($cluster, $partition)";
        return -1;
    }

    return 0;
}

################################################################################
# Deploy a given partition. For that we create the image, setup clients and so #
# on if needed (the user does not have to deal with that!).                    #
#                                                                              #
# We assume we can get all data about the partition. To check if this is the   #
# case, please use valide_partition_data ().                                   #
#                                                                              #
# Input: partition, partition name to deploy.                                  #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub deploy_partition ($$) {
    my ($cluster, $partition) = @_;

    # Do we have an image for this partition?
    if (!OSCAR::ImageMgt::image_exists ($partition)) {
        # If the image does not already exists, we create it.
        if (OSCAR::ImageMgt::create_image ($partition)) {
            carp "ERROR: Impossible to create the basic image\n";
            return -1;
        }

        # Now that we have the basic golden image, we install needed OPKGs into
        # the golden image.

        # For that we first get the list of OPKGs
        # We get the configuration from the OSCAR configuration file.
        require OSCAR::PartitionConfigManager;
        my $oconfig = OSCAR::ConfigManager->new();
        if ( ! defined ($oconfig) ) {
            carp "ERROR: Impossible to get the OSCAR configuration\n";
            return -1;
        }
        my $f = $oconfig->get_partition_config_file_path($cluster, $partition)
                ."/$partition.conf";
        my $config_obj = OSCAR::PartitionConfigManager->new(
            config_file => "$f");
        if ( ! defined ($config_obj) ) {
            carp "ERROR: Impossible to create an object in order to handle ".
                 "the partition configuration file.\n";
            return -1;
        }
        my $partition_config = $config_obj->get_config();
        my $opkgs = $partition_config->{'opkgs'};
        require OSCAR::Utils;
        OSCAR::Utils::print_array (@$opkgs);

        if (OSCAR::ImageMgt::install_opkgs_into_image ($partition, @$opkgs)) {
            carp "ERROR: Impossible to install OPKGs into the basic image\n";
            return -1;
        }
    } else {
        print "INFO: The image already exists, we do not overwrite\n";
    }

    # Make sure that the clients are assigned to the image
    if (assign_client_to_partition ($cluster, $partition)) {
        carp "ERROR: Impossible to assign clients to the partition.\n";
        return -1;
    }
    return 0;
}

# Display partition information.
#
# Input: cluster, cluster name.
# Return: 0 if success, -1 else.
sub display_partition_info ($$) {
    my ($cluster, $partition) = @_;

    if (!defined($cluster) || $cluster eq "" ||
        !defined($partition) || $partition eq "") {
        carp "ERROR: Invalid cluster or partition ($cluster, $partition)\n";
        return -1;
    }

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "file") {
        my $path = $oscar_configurator->get_partition_config_file_path(
                        $cluster,
                        $partition);
        my $f = "$path/$partition.conf";
        if ( ! -f  $f ) {
            carp "Warning: the partition does not exist\n";
            # This is not a error, if the partition does not exist, it means 
            # that the job is already done.
            return 0;
        }
        require OSCAR::PartitionConfigManager;
        my $config_obj = OSCAR::PartitionConfigManager->new(
            config_file => "$f");
        if ( ! defined ($config_obj) ) {
            carp "ERROR: Impossible to create an object in order to handle ".
                 "the partition configuration file.\n";
            return -1;
        }
        $config_obj->print_config();
    } elsif ($config->{db_type} eq "db") {
        carp "ERROR: the uasge of a real db is not yet implemented\n";
        return -1;
    } else {
        carp "ERROR: Unknown ODA type ($config->{db_type})\n";
        return -1;
    }
    return 0;
}

################################################################################
# This function makes sure that the compute nodes of the partition are 
# correctly assigned. One of the task is for instance to assign compute nodes
# to the SIS image. 
# Note that we can typically assume that ODA has all the configuration details,
# we just need to perform needed actions.
#
# Input: cluster, cluster name.
#        partition, partition name.
# Return: 0 if success, -1 else.
#
# TODO: deal with the network domain.
################################################################################
sub assign_client_to_partition ($$) {
    my ($cluster, $partition) = @_;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration\n";
        return undef;
    }
    my $config = $oscar_configurator->get_config();

    my @nodes = get_list_nodes_partition ($cluster, $partition);
    if (! @nodes || scalar (@nodes) == 0) {
        print "INFO: No nodes to assign\n";
        return 0;
    }
    OSCAR::Utils::print_array (@nodes);
    my $cmd;
    foreach my $node (@nodes) {
        require OSCAR::NodeMgt;
        my $node_config = OSCAR::NodeMgt::get_node_config ($cluster,
                                                           $partition,
                                                           $node);
        if (!defined $node_config) {
            carp "ERROR: Impossible to get node configuration ($node).\n";
            return -1;
        }

        # Two cases about the compute nodes: 
        #   1/ nodes are already defined so we need to update info (in order to
        #      be sure everything matches the configuration files.
        #   2/ nodes are not defined, we need to add them.
        # Each of these cases lead to different SIS commands.
        # First we check if the machine is already defined or not
        $cmd = "/usr/bin/mksimachine -L | grep $node";
        oscar_log_subsection ("Is the node already defined? Executing: $cmd");
        my $ret = `$cmd`;
        if ($ret eq "") {
            oscar_log_subsection ("Node $node is not yet defined");
            $cmd = "/usr/bin/mksimachine -A ";
        } else {
            oscar_log_subsection ("Node $node is already defined");
            $cmd = "/usr/bin/mksimachine -U ";
        } 
        $cmd .= "--name $node ".
                "--image $partition ".
                "--ipaddress $node_config->{ip} ".
                "--MACaddress $node_config->{mac} ";
        oscar_log_subsection ("Assigning node $node to partition $partition: ".
                              "executing \"$cmd\"");
        if (system ($cmd)) {
            carp "ERROR: Impossible to assign node $node to partition ".
                "$partition\n";
            return -1;
        }

        $cmd = "/usr/sbin/si_addclients ".
               "--hosts $node ".
               "--interactive NO ".
               "--domainname oscardomain ".
               "--script $partition ";
        oscar_log_subsection ("Executing: $cmd");
        if (system ($cmd)) {
            carp "ERROR: Impossible to add the node ($node)\n";
            return -1;
        }
    }

    if (OSCAR::MAC::__run_setup_pxe (0)) {
        carp "ERROR: Impossible to setup pxe.\n";
        return -1;
    }

    # We update the DHCP configuration file.
    my $interface = $config->{nioscar};
    if (OSCAR::MAC::__setup_dhcpd ($interface)) {
        carp "ERROR: Impossible to setup DHCP.\n";
        return -1;
    }

#    postaddclients

    # Now we are happy, the nodes should be ready to be deployed!!!
    return 0;
}

1;