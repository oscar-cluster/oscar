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
use v5.10.1; # Switch
# Avoid smartmatch warnings when using given
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use OSCAR::Database;
use OSCAR::Package;
use OSCAR::Logger;
use OSCAR::LoggerDefs;

# Up to now, everything is OK.
my $rc=0;

# First of all, enforce that the user running this script is 'root'
if ($< != 0) {
    oscar_log(1, ERROR, "You must be 'root' to run this script.  Aborting");
    exit 1;
}

###############
my @slurm_seen_nodes = ();
open(SCONTROL, "scontrol show partition workq|")
	or (oscar_log(5, ERROR, "Filed to run scontrol show partition workq"), exit 1);
    while(my $line=<SCONTROL>) {
        if($line =~ m/^   Nodes=(.*$)/ ) {
            @slurm_seen_nodes = split(",", $1);
			last; # Parsed; get out of here.
        }
}
close SCONTROL;

my %options = ();
my @errors = ();
my @oda_nodes = ();

# Prepare to check if head must be counted as a compute node.
my $configvalues = getConfigurationValues('slurm');
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

my @oda_seen_nodes = ();
my @slurm_unknown_nodes = ();
foreach my $client_ref (@oda_nodes){
    my $node_name = $$client_ref{name};

    # Check that ODA node is seen by SLURM
    if (! ( $node_name ~~ @slurm_seen_nodes)) {
        oscar_log(5, ERROR, "Node: $node_name defined in OSCAR database but unknown to slurm scheduler");
        $rc++;
        push(@slurm_unknown_nodes, $node_name);
        next;
    }

    # TODO: Check that the nodes are ok. (no errors)
    # my @bad_state = ("down","unknown","offline","buzy","state-unknown");

    # Keep in mind that we saw this node.
    push @oda_seen_nodes, $node_name;
}

# If Some nodes are in ODA but not seen by SLURM, just report that as well.
if (scalar(@slurm_unknown_nodes) > 0) {
    oscar_log(5, ERROR, "Some ODA nodes are not seen by SLURM: ".join(' ',@slurm_unknown_nodes));
    $rc++;
}

# Check that all nodes from SLURM are in the database.
SLURM_NODES: for my $slurm_node (@slurm_seen_nodes) {
    foreach my $client_ref (@oda_nodes) {
        if ($$client_ref{name} eq $slurm_node) {
            next SLURM_NODES; # Found. move to next one.
        }
    }
    # Not found!
    oscar_log(5, ERROR, "SLURM node: $slurm_node not defined in ODA.");
    $rc++;
}

exit $rc;
