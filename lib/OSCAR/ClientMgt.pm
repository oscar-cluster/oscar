package OSCAR::ClientMgt;

#
# Copyright (c) 2007-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
#
#   $Id: ClientMgt.pm 4833 2006-05-24 08:22:59Z bli $
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
# This package provides a set of function for OSCAR client management. This has
# initialy be done to avoid code duplication between the CLI and the GUI.
#

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::Database;
use OSCAR::FileUtils;
use OSCAR::Logger;
use OSCAR::Utils;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            cleanup_clients
            parse_mksimachine_output
            update_client_node_package_status
            );

# The mksimachine command output is something like:
# #Machine definitions
# #Name:Hostname:Gateway:Image
# oscarnode1:oscarnode1.oscardomain:192.168.0.1:oscarimage
# oscarnode2:oscarnode2.oscardomain:192.168.0.1:oscarimage
# #Adapter definitions
# #Machine:Adap:IP address:Netmask:MAC
# oscarnode1:eth0:192.168.0.2:255.255.255.0:
# oscarnode2:eth0:192.168.0.3:255.255.255.0:
sub parse_mksimachine_output ($) {
    my $output = shift;

    my @clients;
    if (!OSCAR::Utils::is_a_valid_string ($output)) {
        return @clients;
    }

    my @lines = split ("\n", $output);
    foreach my $line (@lines) {
        chomp ($line);
        if ($line ne "" && !OSCAR::Utils::is_a_comment ($line)) {
            my @data = split (":", $line);
            my $node_name = $data[0];
            if (!OSCAR::Utils::is_element_in_array ($node_name, @clients)) {
                push (@clients, $node_name);
            }
        }
    }

    return @clients;
}

# Return: 0 if success, -1 else.
sub cleanup_clients {

    # First we get the list of defined clients from the SIS database.
    my $cmd = "mksimachine -L --parse";
    my $output = `$cmd`;
    my @si_clients = parse_mksimachine_output ($output);

    # We do the same for defined clients at OSCAR level
    my (@oscar_clients, $options, $errors);
    OSCAR::Database::get_client_nodes(\@oscar_clients,$options,$errors);

    # Now we check which clients are defined of the file system (typically
    # clients' scripts)
    my @fs_clients;
    my $dir = "/var/lib/systemimager/scripts/";
    my @files = OSCAR::FileUtils::get_files_in_path ($dir);
    foreach my $f (@files) {
        if ($f =~ /^(.*).sh$/) {
            push (@fs_clients, $1);
        }
    }

    #
    # Now we cleanup
    #

    # If a node only has a trace on the file system and not in the SIS database
    # or the OSCAR database, we just delete the script.
    foreach my $n (@fs_clients) {
        if (!OSCAR::Utils::is_element_in_array ($n, @oscar_clients)
            && !OSCAR::Utils::is_element_in_array ($n, @si_clients)) {
            my $file_to_remove = "$dir$n.sh";
            OSCAR::Logger::oscar_log_subsection "[INFO] Removing the ".
                "$file_to_remove script\n";
            unlink ($file_to_remove);
        }
    }

    return 0;
}

# Input: - options, hash reference,
#        - errors, array reference.
sub update_client_node_package_status ($$) {
    my ($options, $errors) = @_;
    my @pkgs = OSCAR::Database::list_selected_packages();
    my @tables = ("Nodes", "Group_Nodes", "Groups", "Packages",
                  "Node_Package_Status");
#    locking("WRITE", \%options, \@tables, \@errors);
    my @client_nodes = ();
    OSCAR::Database::get_client_nodes(\@client_nodes,$options,$errors);
    my @nodes = ();
    foreach my $client_ref (@client_nodes){
        my $node_id = $$client_ref{id};
        my $node_name = $$client_ref{name};
        push @nodes, $node_name;
    }
    my $client_group = "oscar_clients";
    OSCAR::Database::set_group_nodes($client_group,\@nodes,$options,$errors);

    # We assume that all the selected packages should be installed
    my $status = 8;
    foreach my $node_name (@nodes){
        OSCAR::Database::update_node_package_status($options,
                                                    $node_name,
                                                    \@pkgs,
                                                    $status,
                                                    $errors,
                                                    undef);
    }

#    unlock(\%options, \@errors);
}

1;
