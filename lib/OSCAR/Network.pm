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
use OSCAR::Database;
use OSCAR::Logger qw ( verbose );
use OSCAR::Utils;
use POSIX;
use Carp;
use Data::Dumper;
use base qw(Exporter);
@EXPORT = qw(
            get_network_config
            get_network_adapter
            interface2ip
            is_a_valid_ip
            set_network_adapter
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


sub set_network_adapter ($) {
    my $ref = shift;

    for (my $l=0; $l < scalar (@$ref); $l++) {
        my $h = @$ref[$l]->{_vars};

        next if (!defined $h->{'_client'});
        next if (!defined $h->{'_ip'});

        print "-> [INFO] Adding a new network adapter\n";
        print Dumper $h;
        my %data =  (
                    ip      => $h->{'_ip'},
                    mac     => $h->{'_mac'},
#                     name    => $h->{'_devname'},
#                     node_id => "1",
                    );
        if (OSCAR::Database::set_nics_with_node (
            $h->{'_devname'},
            $h->{'_client'},
            \%data,
            undef,
            undef) != 1) {
            carp "ERROR: Impossible to set the NICs to the node";
            return -1;
        }
    }
    
    return 0;
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

# Returns: array of hashes with the following fields or undef if error
#               client, devname, ip, netmask, mac
sub get_network_adapter ($) {
    my $optref = shift;
    my @res;
    my @t;

    if (defined $optref) {
        OSCAR::Database::get_nics_with_name_node (
            $optref->{'devname'},
            $optref->{'client'},
            \@res,
            undef,
            undef);
    } else {
        # We get the list of all the nodes names
        my $sql = "SELECT * FROM Nics";
        if (OSCAR::Database_generic::do_select ($sql, \@res, undef, undef) != 1) {
            carp "ERROR: Impossible to execute SQL command ($sql)\n";
            return undef;
        }
        for (my $i = 0; $i < scalar(@res); $i++) {
            print "Translating ".$res[$i]->{'node_id'}."...";
            $sql = "Select Nodes.name From Nodes Where Nodes.id='".
                    $res[$i]->{'node_id'}."'";
            my $nodename = OSCAR::Database::oda_query_single_result ($sql, "name");
            print "... $nodename\n";
            $res[$i]->{'client'} = $nodename;
            push (@t, $res[$i]);
        }
    }
    if (scalar @res == 0) {
        return undef;
    } else {
        return \@res;
    }
}

################################################################################
# Get the network configuration from the database.                             #
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
    # TODO: check the return code.
    OSCAR::Database::get_nics_info_with_node($node, 
                                             \@results,
                                             $options,
                                             $errors);
    my $ref = pop @results;
    my $nic_name = $$ref{name};
    if (@results == 1) {
        # TODO: check the return code.
        OSCAR::Database::get_gateway($node,
                                     $interface,
                                     \@results,
                                     $options,
                                     $errors);
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
    my $backup_file = "/etc/hosts.bak-$timestamp";
    copy("/etc/hosts","$backup_file") 
        or (carp "ERROR: Impossible to backup /etc/hosts", return -1);
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
    open(IN,"<$backup_file") 
        or (carp "ERROR: Impossible to open $backup_file", return -1);
    open(OUT,">/etc/hosts") 
        or (carp "ERROR: Impossible to open /etc/hosts", return -1);
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

# This function populate ODA so that we store all data we need. ODA must be
# previously initialized.
#
# Return: 0 if success, -1 else.
sub update_head_nic () {
    my ($cmd, $exit_status);

    require OSCAR::Database_generic;
    require OSCAR::ConfigFile;
    my $interface = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf", 
                                                  undef,
                                                  "OSCAR_NETWORK_INTERFACE");

    if (!OSCAR::Utils::is_a_valid_string ($interface)) {
        carp "ERROR: Impossible to get the NIC to use for deployment";
        return -1;
    }

    # First we save the new interface id into ODA
    OSCAR::Logger::oscar_log_section ("Update NIC info ($interface)");
    my $sql = "UPDATE Clusters ".
              "SET Clusters.headnode_interface='$interface' ".
              "WHERE Clusters.name='oscar'";
    if (!OSCAR::Database_generic::do_update ($sql, "Clusters", undef, undef)) {
        carp "ERROR: Impossible to update the headnode NIC ($sql)";
        return -1;
    }

    # Set headnode NIC data.
    my $binaries_path = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf",
                                                      undef,
                                                      "OSCAR_SCRIPTS_PATH");
    $cmd = "$binaries_path/set_node_nics --network";
    if ($ENV{OSCAR_VERBOSE}) {
        $cmd .= " --verbose";
    }
    if (system ($cmd)) {
        carp "ERROR: Impossible to successfully execute \"$cmd\"";
        return -1;
    }

    OSCAR::Logger::oscar_log_subsection ("Headnode NIC data stored");

    # The above two embeded scripts need to run before all the
    # data for Packages and Packages related table are populated
    # because the above tables contain the primary keys which
    # will be used at the Packages and its related tables.
    # (i.e., The Packages table and Packages related tables are
    # dependent on the above tables(Clusters, Groups, Status, and
    # Nodes) and they can not really insert any data before the
    # above tables populate data and generate the primary key
    # used by the Packages and its sub-tables.

    #
    # Now populate the Packages table with the info from the reachable
    # repositories.
    # TODO: Since this function is about storing network data, the following
    # function should not be there.
    #
    $cmd = "$binaries_path/populate_oda_packages_table";
    if ($ENV{OSCAR_VERBOSE} >= 5) {
        $cmd .= " --debug";
    }
    $exit_status = system($cmd)/256;
    if ($exit_status) {
        carp ("ERROR: Couldn't populate packages table");
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
