package OSCAR::ClientMgt;

#
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
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
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(
            update_client_node_package_status
            );

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
