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
use Net::IPv4Addr;
use OSCAR::Env;
use OSCAR::Database;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::Utils;
use OSCAR::FileUtils;
use POSIX;
use Carp;
use Data::Dumper;
use base qw(Exporter);
@EXPORT = qw(
            get_network_config
            get_network_adapter
            interface2ip
            is_a_valid_ip
            is_head_nic_private
            set_network_adapter
            get_host_ip
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

        oscar_log(5, INFO, "Adding a new network adapter for client $h->{'_client'})");
        print Dumper $h if($OSCAR::Env::oscar_verbose >= 9);

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
                oscar_log(5, ERROR, "Impossible to set the NICs to the node $h->{'_client'}");
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
        oscar_log(5, ERROR, "Invalid NIC id.");
        return (undef, undef, undef);
    }

    my ($ip, $broadcast, $net);
    # open pipes are better for controlling output than backticks
    open(IP_ADDR_SHOW,"/sbin/ip addr show $interface |") 
        or (oscar_log(5, ERROR, "Couldn't run '/sbin/ip addr show $interface'"), return undef);
    while(<IP_ADDR_SHOW>) {
        if(/\s+inet ($ipregex)\/([0-9]{2}) brd ($ipregex) scope .*$/o) {
            ($ip, $net, $broadcast) = ($1,$2,$3);
            $net = Net::IPv4Addr::ipv4_cidr2msk($net);
            last;
        }
    }
    close(IP_ADDR_SHOW);
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
            oscar_log(5, DB, "ERROR: Failed to execute SQL command ($sql)");
            return undef;
        }
        for (my $i = 0; $i < scalar(@res); $i++) {
            $sql = "Select Nodes.name From Nodes Where Nodes.id='".
                    $res[$i]->{'node_id'}."'";
            oscar_log(8, DB, "querying ODA: $sql");
            my $nodename = OSCAR::Database::oda_query_single_result ($sql, "name");
            oscar_log(8, DB, "Translated $res[$i]->{'node_id'} to $nodename");
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
# Compute network base ip adress from an ip adress and its netmask.            #
# Input: ip, an ip adress from the network we need to identify                 #
#        netmask, the netmask in use on this network.                          #
# Output: the ip adress of the network.                                        #
# Example (10.161.222.150,255.255.252.0) will return 10.161.220.0              #
################################################################################
sub get_network_base_ip ($$) {
    my ($ip , $netmask) = @_;
    if (is_a_valid_ip ($ip) == 0) {
        oscar_log(6, ERROR, "Invalid IP adress: ($ip)");
        return undef;
    }
    if (is_a_valid_ip ($netmask) == 0) {
        oscar_log(6, ERROR, "ERROR: Invalid netmask ($netmask)");
        return undef;
    }

    # Compute network from ip and netmask
    my @addrarr = split(/\./, $ip);
    my ( $ipaddress ) = unpack( "N", pack( "C4",@addrarr ) );

    my @maskarr = split(/\./,$netmask);
    $netmask = unpack( "N", pack( "C4", @maskarr ) );

    # Calculate network address by logical AND operation of addr & netmask
    # and convert network address to IP address format
    my $netadd = ( $ipaddress & $netmask );
    my @netarr = unpack( "C4", pack( "N", $netadd ) );
    my $netaddress = join(".", @netarr);
    return $netaddress;
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
        oscar_log(5, ERROR, "IP of the NIC $interface is invalid");
        return undef;
    }
    if (is_a_valid_ip ($netmask) == 0) {
        oscar_log(5, ERROR, "Netmask is invalid");;
        return undef;
    }
    if (is_a_valid_ip ($broadcast) == 0) {
        oscar_log(5, ERROR, "Broadcast is invalid");
        return undef;
    }

    my $startip;
    my ($a, $b, $c, $d) = split(/\./, $ip);

    my $network_base = get_network_base_ip ($ip, $netmask);
    if (is_a_valid_ip ($network_base) == 1) {
        $d++;
        # Check that this is not the head_node ip. If yes, then increment $d
        if ( "$a.$b.$c.$d" eq "$ip" ) {
            $d++ ;
        }
        # Check that $a.$b.$c.$d is not the broadcast address. (strange setup)
        if ( "$a.$b.$c.$d" eq "$broadcast" ) {
            $d++ ;
        }
        $startip = "$a.$b.$c.$d";
    } else {
        oscar_log(5, ERROR, "Unable to compute network adress for ".
             "$a, $b, $c, $d/$netmask");
        return undef;
    }

    # TODO: compute lastip as well (if netmask is not 255, then lastip is not 
    # 254)

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
        oscar_log(5, ERROR, "Cannot update hosts without a valid ip.");
        return -1;
    }
    # 1st backup /etc/hosts
    backup_file_if_not_exist("/etc/hosts")
        or (oscar_log(5, ERROR, "Impossible to backup /etc/hosts"), return -1);
#    OSCAR::Logger::oscar_log_subsection("Backing up /etc/hosts");
#    my $timestamp = `date +\"%Y-%m-%d-%k-%M-%m\"`;
#    chomp $timestamp;
#    my $backup_file = "/etc/hosts.bak-$timestamp";
#    copy("/etc/hosts","$backup_file") 
#        or (carp "ERROR: Impossible to backup /etc/hosts", return -1);
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
    my @aliases = qw(oscar_server nfs_oscar pbs_oscar);
    open(IN,"</etc/hosts.oscarbak") 
        or (oscar_log(5, ERROR, "Impossible to open /etc/hosts.oscarbak"), return -1);
    open(OUT,">/etc/hosts") 
        or (oscar_log(5, ERROR, "Impossible to open /etc/hosts"), return -1);

    oscar_log(3, SUBSECTION, "Adding required entries to /etc/hosts");

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

    # We now check whether the new aliases are unique or not (they should!).
    foreach my $alias (@aliases) {
        my $cmd = "grep $alias /etc/hosts";
        my @res = `$cmd`;
        if (scalar @res > 1) {
            oscar_log(1, ERROR, "Several entries in /etc/hosts include $alias,".
                  " please update your /etc/hosts file.");
        }
    }

    return 0;
}

################################################################################
# This function check if a specific hostname is defined in /etc/hosts.         #
# Comments are ignored and only one entry should exist. If not, this is an     #
# error.                                                                       #
# Parameter: hostname                                                          #
# Return:    hostname IP if success                                            #
################################################################################
sub get_host_ip ($) {
    my $id = shift;

    my $count = 0;
    my $my_ip;
    local *IN;
    open IN, "/etc/hosts"
        or (oscar_log(5, ERROR, "Failed to read hosts file (/etc/hosts)"),return -1);
    while (<IN>) {
        chomp;
        next if /^\s*\#/; # We skip comments
        if (/\s+$id(\s|$|\.)/) {
            if (/^(\d+\.\d+\.\d+\.\d+)\s+/) {
                $count++;
                $my_ip = $1;
            }
        }
    }
    close IN;
    if ($count > 1 && $my_ip ne "") {
#         print " ---------------------------------------------------\n";
#         print " ERROR: the hostname $id is used more than one time \n";
#         print " in /etc/hosts                                      \n";
#         print " ---------------------------------------------------\n";
        return -1;
    }
    if ($count == 0) {
# 	print " ---------------------------------------------------\n";
# 	print " ERROR: the hostname $id could not be found         \n";
# 	print " in /etc/hosts                                      \n";
# 	print " ---------------------------------------------------\n";
        return -1;
    }
    return $my_ip;
}

################################################################################
# This function test if headnode iface is on a private network.
# input: none
# Output: 1 if true
#         0 if false
#         -1 if error.
################################################################################
sub is_head_nic_private () {
    my @res;

    # 1. Get the headnode IP used for cluster deployment.
    require OSCAR::ConfigManager;
    my $oscar_configurator = OSCAR::ConfigManager->new();
    if ( ! defined ($oscar_configurator) ) {
        return -1;
    }
    my $config = $oscar_configurator->get_config();
    my $headnic = $config->{'nioscar'};
    if (!OSCAR::Utils::is_a_valid_string ($headnic)) {
        oscar_log(1, ERROR, "Impossible to get the headnode NIC");
        return -1;
    }

    # 2. Get the subnet
    my ($ip, $broadcast, $net) = interface2ip($headnic);
    my $network_base = get_network_base_ip($ip, $net);
    if (!OSCAR::Utils::is_a_valid_string ($network_base)) {
        oscar_log(5, ERROR, "Impossible to get the network base IP");
        return -1;
    }
    
    # 3. Get the rfc1918 data based in the subnet
    my $sql = "SELECT rfc1918 FROM Networks WHERE base_ip='$network_base';";
    oscar_log(8, DB, "DB Query: $sql");

    # TODO: We should not use a SQl command here, but use a ODA info.
    if (OSCAR::Database_generic::do_select ($sql, \@res, undef, undef) != 1) {
        oscar_log(5, ERROR, "Impossible to execute SQL command ($sql)");
        return -1;
    }

    return $res[0]->{'rfc1918'};
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
        oscar_log(1, ERROR, "Impossible to get the NIC to use for deployment (/etc/oscar/oscar.conf)");
        return -1;
    }

    # First we save the new interface id into ODA
    oscar_log(2, SUBSECTION, "Update NIC info ($interface)");
    my $sql = "UPDATE Clusters ".
              "SET Clusters.headnode_interface='$interface' ".
              "WHERE Clusters.name='oscar'";
    oscar_log(8, DB, "DB Query: $sql");
    if (!OSCAR::Database_generic::do_update ($sql, "Clusters", undef, undef)) {
        oscar_log(5, ERROR, "Impossible to update the headnode NIC in DB.");
        return -1;
    }

    # Set headnode NIC data.
    my $binaries_path = OSCAR::ConfigFile::get_value ("/etc/oscar/oscar.conf",
                                                      undef,
                                                      "OSCAR_SCRIPTS_PATH");
    $cmd = "$binaries_path/set_node_nics --networks";
    if ($OSCAR::Env::oscar_verbose >= 10) {
        $cmd .= " --debug";
    } elsif ($OSCAR::Env::oscar_verbose >= 5) {
        $cmd .= " --verbose";
    }
    if (oscar_system ($cmd)) {
        return -1;
    }

    oscar_log(2, SUBSECTION, "Headnode NIC data stored");

    oscar_log(2, SUBSECTION, "Update /etc/hosts...");
    my ($head_private_ip, $broadcast, $net) = interface2ip ($interface);
    oscar_log(5, INFO, "Head private IP: $head_private_ip");
    if (update_hosts ($head_private_ip)) {
        oscar_log(5, ERROR, "Failed to update the /etc/hosts file.");
        return -1;
    }
    oscar_log(2, SUBSECTION, "/etc/hosts updated successfully.");

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
