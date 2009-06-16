package OSCAR::NodeMgt;

#
#   Copyright 2001-2002 International Business Machines
#                       Sean Dague <japh@us.ibm.com>
#   Copyright (c) 2005 The Trustees of Indiana University.  
#                      All rights reserved.
#   Copyright (c) 2006 Erich Focht <efocht@hpce.nec.com>
#                      All rights reserved.
#   Copyright (c) 2008-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                           Oak Ridge National Laboratory
#                           All rights reserved.
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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::ConfigManager;
use OSCAR::Database;
use OSCAR::Logger;
use OSCAR::Network;
use OSCAR::Package;
use OSCAR::SystemServices;
use OSCAR::SystemServicesDefs;
use SIS::NewDB;
use Data::Dumper;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;
use warnings "all";

@EXPORT = qw(
            add_clients
            delete_clients
            display_node_config
            get_node_config
            set_node_config
            );

my $verbose = $ENV{OSCAR_VERBOSE};
# Where the configuration files are.
our $basedir = "/etc/oscar/clusters";

sub add_clients ($) {
    my $client_refobj = shift;

    $ENV{OSCAR_VERBOSE} = 5;

    OSCAR::Logger::oscar_log_subsection "Adding clients...";
    print Dumper $client_refobj;

    OSCAR::Logger::oscar_log_subsection "Populating the OSCAR database...";
    if (OSCAR::Database::set_node_with_group (
            $client_refobj->{'name'},
            "oscar_clients",
            undef,
            undef,
            "oscar") != 1) {
        carp "ERROR: Impossible to add the clients into the OSCAR database";
        return -1;
    }

    # We have the image name, we need to store the image id in the Nodes table
    # We get that id.
    my @res = OSCAR::Database::get_image_info_with_name (
            $client_refobj->{'imagename'},
            undef,
            undef);
    if (scalar (@res) != 1) {
        carp "ERROR: The image ".$client_refobj->{'imagename'}." is not in ".
             "the database";
        return -1;
    }
    print Dumper (@res);
    my %data =  (
                image_id    => $res[0]->{id},
                );
    if (OSCAR::Database::update_node (
            $client_refobj->{'name'},
            \%data,
            undef,
            undef) != 1) {
        carp "ERROR: Impossible to update node information";
        return -1;
    }

    OSCAR::Logger::oscar_log_subsection "Populating the SIS database...";
    my $cmd = "/usr/sbin/si_addclients --hosts " . $client_refobj->{'name'} . 
              " --script " . $client_refobj->{'imagename'};
    print "-> [INFO] Executing: $cmd\n";
    if (system ($cmd)) {
        carp "ERROR: Impossible to execute $cmd";
        return -1;
    }

    return 0;
}

sub ip_to_hex ($) {
    my ($ip) = @_;
    my @hex = split /\./, $ip;
    return sprintf("%2.2X%2.2X%2.2X%2.2X",@hex);
}

# Return: 0 if success, -1 else.
sub del_ip_node ($) {
    my ($node) = @_;

    if (!OSCAR::Utils::is_a_valid_string ($node)) {
        carp "ERROR: Invalid node name";
        return -1;
    }

    my %h = (devname=>"eth0",client=>$node);
    my @adapter = SIS::NewDB::list_adapter(\%h);
    if (scalar (@adapter) != 1) {
        carp "ERROR: Impossible to retrieve valid data for $node";
        return -1;
    }
    print "Data for node deletion\n";
    print Dumper ($adapter[0][0]);
    # TODO: it is completely weird that we have 2 arrays in one. We should
    # investigate why this is doing that.
    my $ip = $adapter[0][0]->{ip};
    my $hex = ip_to_hex($ip);
    if (!OSCAR::Utils::is_a_valid_string ($hex)) {
        carp "ERROR: Impossible to convert the IP ($ip)";
        return -1;
    }

    # delete ELILO and PXE config files
    for my $file ("/tftpboot/".$hex.".conf", 
                  "/tftpboot/pxelinux.cfg/$hex") {
        unlink($file) if (-l $file || -f $file);
    }

    return 0;
}

# Return: 0 if success, the number of errors else.
sub delete_clients (@) {
    my @clients = @_;

    if (scalar (@clients) == 0) {
        print "--> [INFO] No client to delete\n";
        return 0;
    }

    my $clientstring = join(",",@clients);
    if (!OSCAR::Utils::is_a_valid_string ($clientstring)) {
        OSCAR::Logger::oscar_log_subsection ("No clients to delete");
        return 0;
    }

    my $fail = 0;
    my $cmd;

    my @generic_services = ();
    my @server_services = ();
    my $print_error = 1;

    my $interface = OSCAR::Database::get_headnode_iface(undef, undef);
    my $install_mode = OSCAR::Database::get_install_mode(undef, undef);

    # get the list of generic services
    get_packages_servicelists(\@generic_services, "", undef, undef);

    # get the list of services for servers
    get_packages_servicelists(\@server_services, "oscar_server", undef, undef);

    print ">> Turning off generic services\n";
    foreach my $services_ref (@generic_services) {
        my $generic_service = $$services_ref{service};
        $cmd = "/etc/init.d/$generic_service stop";
        if (system($cmd)) {
            carp("ERROR: Impossible to execute $cmd");
            $fail++;
        }
        foreach my $client (@clients) {
            OSCAR::Logger::oscar_log_subsection "[$client]";
            $cmd = "/usr/bin/ssh $client /etc/init.d/$generic_service stop";
            if (system($cmd)) {
                carp("ERROR: Impossible to execute $cmd");
                $fail++;
            }
        }
    }

    # delete node PXE/ELILO configs
    print ">> delete node PXE/ELILO configs\n";
    foreach my $client (@clients) {
        print "... $client\n";
        if (del_ip_node($client)) {
            carp "ERROR: Impossible to delete IP node ($client)";
            return -1;
        }
    }

    $cmd = "/usr/bin/mksimachine --Delete --name $clientstring";
    print ">> Effectively deleting the nodes ($cmd)\n";
    if (system($cmd)) {
        carp("ERROR: Impossible to execute $cmd");
        $fail++;
    }

    # We get the configuration from the OSCAR configuration file.
    print ">> Clients deleted, running few scripts...\n";
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    OSCAR::Logger::oscar_log_subsection "Executing post_clients phase";
    $cmd = "$config->{binaries_path}/post_clients";
    if (system($cmd)) {
      carp("ERROR: Impossible to execute $cmd");
      $fail++;
    }
    OSCAR::Logger::oscar_log_subsection "Executing post_install phase";
    # We do not check the return code since we may not have connectivity with
    # compute nodes and therefore the script may fail.
    system("$config->{binaries_path}/post_install --force");

    print ">> Re-starting generic services\n";
    foreach my $services_ref (@generic_services) {
        my $generic_service = $$services_ref{service};
        $cmd = "/etc/init.d/$generic_service restart";
        if (system($cmd)) {
            carp("ERROR: Impossible to execute $cmd");
            $fail++;
        }
    }
    OSCAR::Logger::oscar_log_subsection "Re-starting server services";
    foreach my $services_ref (@server_services) {
        my $server_service = $$services_ref{service};
        $cmd = "/etc/init.d/$server_service restart";
        if (system($cmd)) {
            carp("ERROR: Impossible to execute $cmd");
            $fail++;
        }
    }
    
    OSCAR::Logger::oscar_log_subsection "Updating C3 configuration file";
    if (!OSCAR::Package::run_pkg_script("c3", "post_clients", 1, "")) {
        carp("ERROR: C3 configuration file update phase failed.");
        $fail++;
    }
                                                                            
    OSCAR::Logger::oscar_log_subsection "Re-starting client services on ".
                                        "remaining nodes";
    foreach my $services_ref (@generic_services) {
        my $generic_service = $$services_ref{service};
        my $cmd = "$config->{binaries_path}/cexec ".
                  "/etc/init.d/$generic_service restart";
        if (system($cmd)) {
                carp("ERROR: Impossible to execute $cmd");
                $fail++;
        }
    }

    my ($ip, $broadcast, $netmask) = OSCAR::Network::interface2ip($interface);
    $cmd = "mkdhcpconf -o /etc/dhcpd.conf --interface=$interface --gateway=$ip";

    if ($install_mode eq "systemimager-multicast") {
       $cmd = $cmd . " --multicast=yes";
    }

    OSCAR::Logger::oscar_log_subsection "Running mkdhcpconf";
    if (system($cmd)) {
        carp ("ERROR: Impossible to execute $cmd");
        $fail++;
    }

    my $rc = OSCAR::SystemServices::system_service
        (OSCAR::SystemServicesDefs::DHCP(), OSCAR::SystemServicesDefs::STOP());
    if ($rc) {
        carp "ERROR: Impossible to restart DHCPD";
        $fail++;
    }

    return $fail;
}


################################################################################
# Display the configuration for a given node of a given partition of a given   #
# cluster.                                                                     #
#                                                                              #
# Input: cluster_name, name of the target cluster,                             #
#        partition_name, name of the target partition,                         #
#        node_name, name of the node to look for.                              #
# return: 0 if success, -1 else.                                               #
################################################################################
sub display_node_config ($$$) {
    my ($cluster_name, $partition_name, $node_name) = @_;
    my $node_config;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration.\n";
        return -1;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "file") {
        my $path = $oscar_configurator->get_node_config_file_path (
                    $cluster_name,
                    $partition_name,
                    $node_name);
        if ( !defined ($path) || ! -d $path ) {
            carp "ERROR: Undefined node.\n";
            return -1;
        }
        require OSCAR::NodeConfigManager;
        my $config_file = "$path/$node_name.conf";
        if ( ! -f $config_file ) {
            # if the configuration file does not exist, it means that the node
            # has been added to the partition but not yet defined. This is not
            # an error.
            return -1;
        }
        oscar_log_subsection("Parsing node configuration file: $config_file");
        my $config_obj = OSCAR::NodeConfigManager->new(
            config_file => "$config_file");
        if ( ! defined ($config_obj) ) {
            carp "ERROR: Impossible to create an object in order to handle ".
                 "the node configuration file.\n";
            return -1;
        }
        $node_config = $config_obj->get_config();
        if (!defined ($node_config)) {
            carp "ERROR: Impossible to load the node configuration file\n";
            return -1;
        } else {
            $config_obj->print_config();
            if ($node_config->{'type'} eq "virtual") {
                require OSCAR::VMConfigManager;
                my $vm_config_file = "$path/vm.conf";
                my $vm_config_obj = OSCAR::VMConfigManager->new(
                    config_file => "$vm_config_file");
                if ( ! defined ($config_obj) ) {
                    carp "ERROR: Impossible to create an object in order to ".
                         "handle the node configuration file.\n";
                    return -1;
                }
                $vm_config_obj->print_config();
            }
        }
    } elsif ($config->{db_type} eq "db") {
        carp "Real db are not yet supported\n";
        return -1;
    } else {
        carp "ERROR: Unknow ODA type ($config->{db_type})\n";
        return -1;
    }
    return 0;
}

################################################################################
# Get the node configuration for a given node of a given partition of a given  #
# cluster.                                                                     #
#                                                                              #
# Input: cluster_name, name of the target cluster,                             #
#        partition_name, name of the target partition,                         #
#        node_name, name of the node to look for.                              #
# return: a hash representing the node configuration, undef if error.          #
#         Note that a description of the hask is available in                  #
#         OSCAR::NodeConfigManager.                                            #
################################################################################
sub get_node_config ($$$) {
    my ($cluster_name, $partition_name, $node_name) = @_;
    my $node_config;

    # We get the configuration from the OSCAR configuration file.
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        carp "ERROR: Impossible to get the OSCAR configuration.\n";
        return undef;
    }
    my $config = $oscar_configurator->get_config();

    if ($config->{db_type} eq "file") {
        my $path = $oscar_configurator->get_node_config_file_path (
                    $cluster_name,
                    $partition_name,
                    $node_name);
        if ( !defined ($path) || ! -d $path ) {
            carp "ERROR: Undefined node.\n";
            return undef;
        }
        require OSCAR::NodeConfigManager;
        my $config_file = "$path/$node_name.conf";
        if ( ! -f $config_file ) {
            # if the configuration file does not exist, it means that the node
            # has been added to the partition but not yet defined. This is not
            # an error.
            return undef;
        }
        oscar_log_subsection("Parsing node configuration file: $config_file");
        my $config_obj = OSCAR::NodeConfigManager->new(
            config_file => "$config_file");
        if ( ! defined ($config_obj) ) {
            carp "ERROR: Impossible to create an object in order to handle ".
                 "the node configuration file.\n";
            return undef;
        }
        $node_config = $config_obj->get_config();
        if (!defined ($node_config)) {
            carp "ERROR: Impossible to load the node configuration file\n";
            return undef;
        } 
    } elsif ($config->{db_type} eq "db") {
        carp "Real db are not yet supported\n";
        return undef;
    } else {
        carp "ERROR: Unknow ODA type ($config->{db_type})\n";
        return undef;
    }
    return $node_config;
}

################################################################################
# Set the configuration of the node. Note that a node is always part of a      #
# cluster and of a partition.                                                  #
#                                                                              #
# Input: cluster, cluster name the node belong to,                             #
#        partition, partition name the node belong to,                         #
#        node_name, node name,                                                 #
#        node_config, a hash representing the node configuration. To know the  #
#                     format of the hash, please refer to                      #
#                     OSCAR::NodeConfigManager.                                #
# Return: 0 if success, -1 else.                                               #
################################################################################
sub set_node_config ($$$$) {
    my ($cluster, $partition, $node_name, $node_config) = @_;

    if ($verbose) {
        oscar_log_section "Saving node configuration...";
        oscar_log_subsection "Cluster: $cluster";
        oscar_log_subsection "Partition: $partition";
        oscar_log_subsection "Node: $node_name";
    }

    # Few asserts to be everything is fine.
    if (!defined ($cluster) || $cluster eq "" ||
        !defined ($partition) || $partition eq "" ||
        !defined ($node_config) || $node_config eq "") {
        carp "ERROR: missing data, impossible to set node configuration\n";
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
        my $path = $oscar_configurator->get_node_config_file_path (
                    $cluster,
                    $partition,
                    $node_name);
        if ( ! -d $path ) {
            carp "ERROR: Undefined node\n";
            return -1;
        }
        require OSCAR::NodeConfigManager;
        my $config_file = "$path/$node_name.conf";
        my $config_obj = OSCAR::NodeConfigManager->new(
            config_file => "$config_file");
        if ( ! defined ($config_obj) ) {
            carp "ERROR: Impossible to create an object in order to handle ".
                 "the node configuration file.\n";
            return -1;
        }
        $config_obj->set_config($node_config);
    } elsif ($config->{db_type} eq "db") {
        carp "Real db are not yet supported\n";
        return -1;
    } else {
        carp "ERROR: Unknow ODA type ($config->{db_type})\n";
        return -1;
    }
    return 0;
}

1;
