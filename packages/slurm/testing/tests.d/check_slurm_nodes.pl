#!/usr/bin/perl 
#===============================================================================
#
#         FILE: check_ganglia_nodes.pl
#
#        USAGE: ./check_ganglia_nodes.pl  
#
#  DESCRIPTION: Check that gstat returns correct node list
#
#       AUTHOR: Olivier LAHAYE (olivier.lahaye@cea.fr), 
# ORGANIZATION: CEA
#      VERSION: 1.0
#      CREATED: 11/09/2014 16:19:56
#===============================================================================

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# This script checks to see if the number of OSCAR clients (+ headnode)
# equals the number of hosts Ganglia sees by using gstat

#  Copyright (c) 2014   Commissariat à L'Énergie Atomique et
#                       aux Énergies Alternatives
#                       Olivier Lahaye <olivier.lahaye@cea.fr>
#                       All rights reserved.

# This script is inspired by original test_user script from ganglia opkg
# with the following (c):
# (C)opyright Bernard Li <bli@bcgsc.ca>
#             Erich Focht <efocht@hpce.nec.com>
#             Geoffroy Vallee <valleegr@ornl.gov>

use strict;
use warnings;
use v5.10.1; # Switch
# Avoid smartmatch warnings when using given
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use OSCAR::Database;
use OSCAR::Network;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::Utils;

my $return_code = 0;


# This routine will return the private IP addr of the cluster.
sub get_cluster_private_ip() {
    # Get the head NIC.
    # OL: Why not use OSCAR::Database::get_headnode_nic(undef,undef) instead?
    my $headnic = OSCAR::Database::get_headnode_iface(undef,undef);
    if (!OSCAR::Utils::is_a_valid_string ($headnic)) {
        oscar_log(1, ERROR, "ERROR: Unable to get the headnode NIC");
        return undef;
    }

    # Get the ip of this NIC.
    my ($head_ip, $broadcast, $net) = OSCAR::Network::interface2ip($headnic);
    if (!OSCAR::Utils::is_a_valid_string ($head_ip)) {
        oscar_log(1, ERROR, "Unable to get head private IP");
        return "0.0.0.0";
    }
    return $head_ip;
}

sub get_cluster_head_private_aliases() {
    my $private_ip = get_cluster_private_ip();
    # Get the hostname and aliases associated with this NIC.
    my $cmd = "grep $private_ip /etc/hosts";
    my $private_hostnames = `$cmd`;
    if (!OSCAR::Utils::is_a_valid_string ($private_hostnames)) {
        oscar_log(1, ERROR, "Unable to get private hostnames ($cmd)");
        return undef;
    }
    my @hostnames = split (" ", $private_hostnames);
    return @hostnames;
}

# return true if hostname is one of the private ip aliases
sub is_cluster_head($) {
    my $head_hostname = shift;
    my @aliases = get_cluster_head_private_aliases();
    if ($head_hostname ~~ @aliases) {
        return 1;
    } else {
        return undef;
    }
}

# return a table will all hosts returned by gstat
sub get_ganglia_nodes() {
    my $cmd = "gstat --all -l -1  |cut -d' ' -f1|sort|tr '\n' ' '";
    my $ganglia_nodes = `$cmd`;
    my @nodes = split (" ", $ganglia_nodes);
    return @nodes;
}

# Get the nodes to be checked from the ODA.
my %options = ();
my @errors = ();
my @oda_nodes = ();
if(!get_nodes(\@oda_nodes,\%options,\@errors)) {
    oscar_log(1, ERROR, "Can't get OSCAR defined nodes from database.");
    $return_code++;
}

# Get the list of ganglia seen nodes (including head).
my @ganglia_nodes = get_ganglia_nodes();

my @ganglia_head_aliases = get_cluster_head_private_aliases();

########## Now the tests ###########

# 1st: check that ODA node count and ganglia node count matches.
my $gnc = scalar(@ganglia_nodes);
my $onc = scalar(@oda_nodes);
if ($gnc != $onc) {
    oscar_log(1, ERROR, "Ganglia node count ($gnc) and OSCAR Database node count ($onc) Don't match.");
    $return_code++;
} else {
    oscar_log(5, INFO, "OK: Ganglia node count ($gnc) and OSCAR Database node count ($onc) match.");
}


# 2nd: check that all ODA nodes are seen by ganglia.
# We use 'name' that containes the node name while 'hostname' is the public hostname
# public hostname doesn't match on cluster with private network. Indeed, on head node,
# name points to the correct ganglia hostname while hostname points to the public fqdn host name
# which has nothing to do with cluster config.
# $$node{'name'} => "oscar-cluster" (which matches OSCAR interface IP)
# $$node{'hostnamename'} => "my-server" (which match public IP)
for my $node (@oda_nodes) {
    next if ($$node{'name'} ~~ @ganglia_nodes);
    oscar_log(1, ERROR, "Node [$$node{'name'}] not seen by ganglia.");
    $return_code++;
}

if($return_code == 0) {
    oscar_log(5, INFO, "OK: All OSCAR Database nodes are seen by ganglia");
}

# 3rd: check that we have a uniq head in gstat report.
my $head_found=0;
foreach my $head (@ganglia_head_aliases) {
    if ($head ~~ @ganglia_nodes) {
        $head_found+=1;
    }
}
given ($head_found) {
    when (0) {
        oscar_log(1, ERROR,"Headnode missing from gstat report!");
        $return_code++; }
    when (1) {
        oscar_log(5, INFO, "OK: Found one uniq head in gstat report."); }
    default {
        oscar_log(1, ERROR, "Multiple aliases of headnode in gstat report!");
        $return_code++; }
}

exit $return_code;
