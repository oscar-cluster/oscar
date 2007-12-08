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
use OSCAR::Logger qw ( verbose );
use POSIX;
use Carp;
use base qw(Exporter);
@EXPORT = qw(
            get_network_config
            interface2ip
            update_hosts
            );

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# package scoped regex for an ip address.  If we ever need to support
# ipv6, we just need to change it here
my $ipregex = '\d+\.\d+\.\d+\.\d+';

#
# interface2ip - returns the ip addr, broadcast, and netmask of an interface
#

sub interface2ip ($) {
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

################################################################################
# Update the /etc/host configuration file in order to include OSCAR stuff.     #
#                                                                              #
# Input: ip, IP address of the headnode.                                       #
sub update_hosts ($) {
    my $ip = shift;
    if( ! $ip ) {   # mjc - 12/13/01
        croak( "Cannot update hosts without a valid ip.\n" );
    }
    verbose("Backing up /etc/hosts");
    copy("/etc/hosts","/etc/hosts.bak") or return undef;
    my $short;
    my $hostname = qx/hostname/;
    chomp($hostname);
    if($hostname =~ /\./) {
        $short = $hostname;
        $short =~ s/\..*//;
        if($short eq $hostname) {
            $short=undef;
        }
    }
    my @aliases=qw(oscar_server nfs_oscar pbs_oscar);
    open(IN,"</etc/hosts.bak") or return undef;
    open(OUT,">/etc/hosts") or return undef;
    verbose("Adding required entries to /etc/hosts");

    # mjc - 11/12/01 - start
    # - If the ip is in there, add the oscar aliases if they
    #   aren't on the list.
    # - If the ip is not in there, add the line.
    # - If you stumble across another line in the file with a different ip
    #   but the same hostname, pull it out of the file and add it back in
    #   only after we have added the line for this specified ip
    my @hostlines = ();
    my $line;
    my $found=0;

    while ($line=<IN>) {
        chomp $line; # mjc - 12/13/01
        if( $line =~ /^$ip\s+/ ) {
            $line =~ /^([^#]+)(#.*)?$/;
            my $body = $1;
            my $comment = $2||"";
            # Same ip, grab all the items on the line and add the oscar 
            # aliases if they aren't already there.
            $found = 1;
            my @items = split( /\s+/, $body );
            foreach my $alias (@aliases) {
                    push @items, $alias unless grep {$alias eq $_} @items;
            }
            # print the modified line.
            print OUT join( " ", @items ), " $comment\n";
        } elsif( $line =~ /$hostname/ ) {  # mjc - 12/13/01
            # Not the same ip, but same hostname, save this line for now
            $hostlines[$#hostlines + 1] = $line;
        } else {
            # Not a line we're interested in changing
            print OUT $line."\n"; # mjc - 12/13/01
        }
    }
    # If there wasn't a line there, add it now.
    if(!$found) {
        print OUT "$ip $hostname $short ". join( " ", @aliases )."\n";
    }
    # Add back in any lines found with the same hostname but different ip
    foreach $line ( @hostlines ) {
        print OUT $line."\n"; # mjc - 12/13/01
    }
    # mjc - 11/12/01 - end

    close(OUT);
    close(IN);
}

1;
