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
#   Copyright (c) 2008 Geoffroy Vallee <valleegr@ornl.gov>
#                      Oak Ridge National Laboratory

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw($VERSION @EXPORT);
use File::Copy;
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
            is_a_valid_ip
            update_hosts
            update_head_nic
            );

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

# package scoped regex for an ip address.  If we ever need to support
# ipv6, we just need to change it here
my $ipregex = '\d+\.\d+\.\d+\.\d+';

# Check if a given IP is valid.
#
# Return: 1 (true) if the IP is valid; 0 (false) else.
sub is_a_valid_ip ($) {
    my $ip = shift;

    return 0 if (!defined $ip);
    return 0 if ($ip eq "0.0.0.0");
    return 0 if ($ip !~ /^$ipregex$/);

    return 1;
}


################################################################################
# Returns the ip addr, broadcast, and netmask of an interface.                 #
#                                                                              #
# Input: interface, network interface id (e,g., eth0).                         #
# Return: the IP address, the broadcast address and the network mask; undef if #
#         error.                                                               #
################################################################################
sub interface2ip ($) {
    my $interface = shift;

    # Some sanity check
    if ( !defined ($interface) || $interface eq "" ) {
        carp "ERROR: Invalid NIC id.";
        return (undef, undef, undef);
    }

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
#         Returns undef if errors.                                             # 
################################################################################
sub get_network_config ($$$) {
    my ($interface, $options, $errors) = @_;

    # Parse the IP address
    my ($ip, $broadcast, $netmask) = interface2ip($interface);
    if (is_a_valid_ip ($ip) == 0) {
        carp "ERROR: IP of the NIC $interface is invalid";
        return undef;
    }
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
# Return: 0 if success, -1 else.                                               #
################################################################################
sub update_hosts ($) {
    my $ip = shift;
    if( ! is_a_valid_ip($ip) ) {
        carp ( "Cannot update hosts without a valid ip.\n" );
        return -1;
    }
    OSCAR::Logger::oscar_log_subsection("Backing up /etc/hosts");
    my $timestamp = `date +\"%Y-%m-%d-%k-%M-%m\"`;
    chomp $timestamp;
    copy("/etc/hosts","/etc/hosts.bak-$timestamp") 
        or (carp "ERROR: Impossible to backup /etc/hosts", return undef);
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
    OSCAR::Logger::oscar_log_subsection("Adding required entries to /etc/hosts");

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

    return 0;
}

# Return: 0 if success, -1 else.
sub update_head_nic () {
    require OSCAR::Database_generic;
    require OSCAR::ConfigFile;
    my $interface = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf", 
                                                  undef,
                                                  "OSCAR_NETWORK_INTERFACE");

    # First we save the new interface id into ODA
    print "\tNew interface: $interface\n";
    my $sql = "UPDATE Clusters ".
              "SET Clusters.headnode_interface='$interface' ".
              "WHERE Clusters.name='oscar'";
    if (!OSCAR::Database_generic::do_update ($sql, "Clusters", undef, undef)) {
        carp "ERROR: Impossible to update the headnode NIC ($sql)";
        return -1;
    }

    # Then we update the rest of ODA
    require OSCAR::ConfigFile;
    my $binaries_path = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf",
                                                      undef,
                                                      "OSCAR_SCRIPTS_PATH");
    my $cmd = "$binaries_path/set_node_nics --network";
    if (system ($cmd)) {
        carp "ERROR: Impossible to successfully execute \"$cmd\"";
        return -1;
    }

    return 0;
}

1;

__END__

=head1 NAME

Network.pm - A set of functions for basic networking tasks.

=head1 Exported Functions

=over 8

=item my @data = get_network_config($interface, $options, $error_prefix) 

where:

=over 4

=item interface network interface id used by OSCAR (e.g. eth0).

=item options   hash reference for options.

=item errors, array references for errors.

=back

The result is an array with the following pattern:

=over 2

=item result[0] is netmask,

=item result[1] is dnsdomainname,

=item result[2] is the gateway IP,

=item result[3] is startip

=back

=item interface2ip($interface) 

Returns the IP address, broadcast, and netmask of an interface/

=item is_a_valid_ip($ip) 

Check if a given IP is valid. Returns 1 if the IP is valid, 0 else.

=item update_hosts

=item update_head_nic

Update the headnode nic based on the /etc/oscar/oscar.conf file. This updates all the data about the headnode NIC used for cluster management and ensure the data is propageted in OSCAR.

my $rc = update_head_nic (); # return 0 if success, -1 else.

=back

=cut
