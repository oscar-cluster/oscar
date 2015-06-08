#!/usr/bin/perl 
#############################################################################
####
####   This program is free software; you can redistribute it and/or modify
####   it under the terms of the GNU General Public License as published by
####   the Free Software Foundation; either version 2 of the License, or
####   (at your option) any later version.
####
####   This program is distributed in the hope that it will be useful,
####   but WITHOUT ANY WARRANTY; without even the implied warranty of
####   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
####   GNU General Public License for more details.
####
####   You should have received a copy of the GNU General Public License
####   along with this program; if not, write to the Free Software
####   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
####
####   Copyright (c) 2013-2014 CEA - Commissariat a l'Energie Atomique et
####                            aux Energies Alternatives
####                            All rights reserved.
####   Copyright (C) 2013-2014  Olivier LAHAYE <olivier.lahaye@cea.fr>
####                            All rights reserved.
####
#### $Id: $
####
################################################################################

use strict;
use warnings;

use OSCAR::Database;
use OSCAR::Package;
use XML::Simple;
use OSCAR::Logger;
use OSCAR::LoggerDefs;

# Up to now, everything is OK.
my $rc=0;

# First of all, enforce that the user running this script is 'root'
if ($< != 0) {
    oscar_log(1, ERROR, "You must be 'root' to run this script.  Aborting");
    exit 1;
}

my $pbsnodes_cmd;
if (-x '/usr/bin/pbsnodes') {
   $pbsnodes_cmd='/usr/bin/pbsnodes -x';
} else {
   $pbsnodes_cmd='/opt/pbs/bin/pbsnodes -x';
}

my $xml = new XML::Simple;
open CMD, "$pbsnodes_cmd |" or die "Error: $!";
my $pbsnodes_hash = $xml->XMLin(<CMD>, ForceArray => [ 'Node' ]);
close CMD;

# Get nodes seen by PBS.
my @pbs_seen_nodes = keys %{$pbsnodes_hash->{Node}};

my %options = ();
my @errors = ();
my @oda_nodes = ();

# Prepare to check if head must be counted as a compute node.
my $configvalues = getConfigurationValues('torque');
my $compute_on_head = ($configvalues->{compute_on_head}[0]);
if($compute_on_head) {
    # Compute on head: we get ALL nodes.
    if(!get_nodes(\@oda_nodes,\%options,\@errors)) {
        oscar_log(5, ERROR, "Can't get OSCAR defined nodes from database.");
        $rc++;
    }
} else {
   # Don't compute on head: we get only client nodes.
    if(!get_client_nodes(\@oda_nodes,\%options,\@errors)) {
        oscar_log(5, ERROR, "Can't get OSCAR defined nodes from database.");
        $rc++;
    }
}

my $check_server_priv_nodes=0;
my @oda_seen_nodes = ();
my @pbs_unknown_nodes = ();
foreach my $client_ref (@oda_nodes){
    my $node_name = $$client_ref{hostname};

    # Check that ODA node is seen by PBS
    if (! defined($pbsnodes_hash->{Node}->{$node_name})) {
        oscar_log(5, ERROR, "Node: $node_name defined in OSCAR database but unknown to PBS scheduler");
        $rc++;
        push(@pbs_unknown_nodes, $node_name);
        next;
    }

    # If $$client_ref{gpu_num} is not defined, it means gpus=0;
    $$client_ref{gpu_num} = 0 if (! defined($$client_ref{gpu_num}));
    $pbsnodes_hash->{Node}->{$node_name}->{gpus} = 0 if (! defined($pbsnodes_hash->{Node}->{$node_name}->{gpus}));

    # Fake head gpu count test on head. (We disable gpus on head).
    $pbsnodes_hash->{Node}->{$node_name}->{gpus} = $$client_ref{gpu_num} if ($$client_ref{group_name} eq "oscar_server");

    # Check that ODA node options are the same as in PBD (np= gpus=)
    if (($pbsnodes_hash->{Node}->{$node_name}->{np} != $$client_ref{cpu_num}) ||
        ($pbsnodes_hash->{Node}->{$node_name}->{gpus} != $$client_ref{gpu_num})) {
            oscar_log(5, ERROR, "Node: $node_name PBS config differs from ODA: PBS(np=$pbsnodes_hash->{Node}->{$node_name}->{np},gpus=$pbsnodes_hash->{Node}->{$node_name}->{gpus}) ODA(np=$$client_ref{cpu_num},gpus=$$client_ref{gpu_num})");
            $rc++;
            $check_server_priv_nodes=1;
     }

    # Check that the nodes are ok. (no errors)
    my @bad_state = ("down","unknown","offline","buzy","state-unknown");
    for my $state (split ',', $pbsnodes_hash->{Node}->{$node_name}->{state}) {
        if ("$state" ~~ @bad_state) {
            oscar_log(5, ERROR, "Node: $node_name bad state: $state");
            $rc++;
        }
    }

    # Keep in mind that we saw this node.
    push @oda_seen_nodes, $node_name;
}

# If there were differences between ODA and what PBS sees, display a tip.
if ($check_server_priv_nodes) {
    oscar_log(5, ERROR, "PBS config differs from ODA: Check server_priv/nodes");
}

# If Some nodes are in ODA but not seen by PBS, just report that as well.
if (scalar(@pbs_unknown_nodes) > 0) {
    oscar_log(5, ERROR, "Some ODA nodes are not seen by PBS: ".join(' ',@pbs_unknown_nodes));
    $rc++;
}

# Check that all nodes from PBS are in the database.
PBS_NODES: for my $pbs_node (@pbs_seen_nodes) {
    foreach my $client_ref (@oda_nodes) {
        if ($$client_ref{hostname} eq $pbs_node) {
            next PBS_NODES; # Found. move to next one.
        }
    }
    # Not found!
    oscar_log(5, ERROR, "PBS node: $pbs_node not defined in ODA.");
    $rc++;
}

exit $rc;
