package OSCAR::Network;

#   $Id$

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

#   Copyright 2002 International Business Machines
#                  Sean Dague <japh@us.ibm.com>

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use vars qw($VERSION @EXPORT);
use OSCAR::Database qw (
                        get_gateway
                        get_nics_info_with_node
                       );
use POSIX;
use Carp;
use base qw(Exporter);
@EXPORT = qw(
            get_network_config
            interface2ip
            );

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# package scoped regex for an ip address.  If we ever need to support
# ipv6, we just need to change it here
my $ipregex = '\d+\.\d+\.\d+\.\d+';

#
# interface2ip - returns the ip addr, broadcast, and netmask of an interface
#

sub interface2ip {
    my $interface = shift;
    my ($ip, $broadcast, $net);

    # open pipes are better for controlling output than backticks
    open(IFCONFIG,"/sbin/ifconfig $interface |") 
        or (carp("Couldn't run 'ifconfig $interface'"), return undef);
    while(<IFCONFIG>) {
        if(/^.*:($ipregex).*:($ipregex).*:($ipregex)\s*$/o) {
            ($ip, $broadcast, $net) = ($1,$2,$3);
            last;
        }
    }
    close(IFCONFIG);
    return ($ip, $broadcast, $net);
}

################################################################################
# Get the network configuration.                                               #
# Input: - interface, network interface id used by OSCAR (e.g. eth0),          #
#        - options, hash reference for options (GV: i have no clue of what the #
#                   hash should looks like).                                   #
#        - errors, array references for errors.                                #
# Output: an array with the following pattern                                  #
#           * result[0] is netmask,                                            #
#           * result[1] is dnsdomainname,                                      #
#           * result[2] is the gateway IP,                                     #
#           * result[3] is startip.                                            #
################################################################################
sub get_network_config ($$$) {
    my ($interface, $options, $errors) = @_;

    # Parse the IP address
    my ($ip, $broadcast, $netmask) = interface2ip($interface);
    my ($a, $b, $c, $d) = split(/\./, $ip);
    if ($d == 1) {
        $d++;
    } else {
        $d = 1;
    }
    my $startip = "$a.$b.$c.$d";

    # Most of this code is borrowed from scripts/oscar_wizard
    # It has been changed slightly for the command line

    my $gw;
    my @tables = qw( nodes nics networks );
    my @results;
    my $node = "oscar_server";
    get_nics_info_with_node($node, \@results, $options, $errors);
    my $ref = pop @results;
    my $nic_name = $$ref{name};
    if (@results == 1)
    {
        get_gateway($node, $interface, \@results, $options, $errors);
        my $gw_ref = pop @results if @results;
        $gw = $$gw_ref{gateway};
    }
    $gw ||= $ip;

    my $hostname = (uname)[1];
    my ($shorthostname) = split(/\./,$hostname, 2);
    my $dnsdomainname = `dnsdomainname`;
    chomp($dnsdomainname);

    # If the domainname is blank, stick in a default value
    if (!$dnsdomainname) {
        $dnsdomainname = "oscardomain";
    }

    my @result;
    # If you want to return more info, add that at the end of the array, doing
    # so the existing code will continue to work.
    push (@result, $netmask);
    push (@result, $dnsdomainname);
    push (@result, $gw);
    push (@result, $startip);

    return (@result);
}

1;
