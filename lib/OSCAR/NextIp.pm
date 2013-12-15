package NextIp;

# $Id$
# 
# Descr: Search for next available IP to auto-assign to a node.
#
# Copyright (c) 2004 Oak Ridge National Laboratory.
#                    All rights reserved.
#


# OL: FIXME: FlatIpDB package does not exists.
# Commenting out the code for the moment.
#use FlatIpDB;
use Carp;

use warnings;
use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
@EXPORT = qw(next_ip next_ip_rollover set_debug_mode);

use constant { FALSE=>0, TRUE=>1 };
use constant { NETWORK_FULL => "0.0.0.0" };  #Sentinel value for full/error

use constant { E_MISSING_OCTET    => -1,
               E_NONDIGIT_OCTET   => -2,
               E_OUTOFRANGE_OCTET => -3,
               E_MISC             => -4,
             };

our $VERSION    = (q$Revision$ =~/\d+/g);
our $DEBUG      = FALSE;         # control debug printing (off by default)

# Sub-rtn specific dbg prints (may not exist)
use constant { DBG_next_ip            => 0,
               DBG_next_ip_rollover   => 0,
               DBG_set_debug_mode     => 0,
               DBG_get_addresses      => 0,
               DBG_cmp_addrs          => 0,
               DBG_address_exists     => 0,
               DBG_valid_octets       => 0,
               DBG_address_on_network => 0,
               DBG_increment_address  => 0,
               DBG_increment_octets   => 0,
               DBG_prn_dbg            => 0,
               DBG_apierror           => 0,
               DBG_get_error_msg      => 0,
			 };


my @exclude_addrs = qw(127.0.0.1);  # Should probably be an arg as well


#  Input: network, netmask [ex. "192.168.1.0", "255.255.255.0"]
# Return: nextIP (success) / undef (error)
sub next_ip
{
	apierror("missing argument(s), expect 2 args") if( scalar(@_) < 2);
	my $network = shift;
	my $netmask = shift;
	my ($ip,$next_ip) = undef;

	prn_dbg("network=($network) netmask=($netmask)") if($DEBUG or DBG_next_ip);

	my @addrs = get_addresses();
	prn_dbg("addresses " . join("\n", @addrs)) if($DEBUG or DBG_next_ip);

	 # Append any address that should be excluded
	push @addrs, @exclude_addrs;
	prn_dbg("addresses + excludes " . join("\n", @addrs)) if($DEBUG 
	                                                          or DBG_next_ip);

	 # XXX: For now always just start at (network + 1)     :-(
	my @tmp = split(/\./, $network);
	$tmp[3] += 1;
	$ip = join('.', @tmp);

	do {

		$next_ip = increment_address($ip, $network, $netmask);
		$ip = $next_ip;

	} while( address_exists($next_ip, @addrs) and defined($next_ip) );

	return( (defined($next_ip))? $next_ip : undef ); 
}


# Descr: This will take a list of network/mask pairs and iterate
#        over them looking for the next_ip.  
# XXX: NOT IMPLEMENTED YET.
sub next_ip_rollover
{ 
	print STDERR "STUB: " . (caller(0))[3] . " not implemented yet\n";
	return(undef); 
}


# Descr: Enable(>=1) / Disable (0) the debug printing
sub set_debug_mode
{
	apierror("missing argument(s), expect 1 args") if( scalar(@_) < 1);
	my $mode = shift;
	$DEBUG = ($mode == FALSE)? FALSE : TRUE;
}




# XXX: eventually this will read from ODA
# Return: Array of addresses (strings in dotted-quad fmt)
sub get_addresses
{
    # OL: FIXME: FlatIpDB package does not exists.
    # Commenting out the code for the moment.
	#return( FlatIpDB::read_IP_database() );
}


#  Descr: Compare two IP addresses, returning values similar to cmp
# Return: (0) a&b equal, (1) b is greater, (-1) b is greater
sub cmp_addrs
{
	apierror("missing argument(s), expect 2 args") if( scalar(@_) < 2);
	my $addrA = shift;
	my $addrB = shift;

	my @A = split(/\./, $addrA);
	my @B = split(/\./, $addrB);

	prn_dbg(" (".join(" ",@A).") <=> (".join(" ",@B).")") if($DEBUG 
	                                                         or DBG_cmp_addrs);
	return( $A[3] <=> $B[3] );
}


#  Descr: Sequential search of a list of addresses for a given address
# Return: TRUE (exists) / FALSE (not exist)
#  Usage: $ip = $a if( address_exists($a, @addrs) == FALSE );
sub address_exists
{
	apierror("missing argument(s), expect 2 args") if( scalar(@_) < 2);
	my $ip    = shift;
	my @addrs = @_;
	my $found = FALSE;

	foreach my $addr (@addrs) {
		prn_dbg(" ip=($ip)   addr=($addr) ") if($DEBUG or DBG_address_exists);
		next if(not defined($ip) ); #FIXME: uninitialized value hack
		$found = TRUE if( $ip eq $addr );
	}

	prn_dbg("\n END ***  $ip found=($found) ***\n") if($DEBUG 
	                                                   or DBG_address_exists);

	return($found);
}


#  Input: $ip, \$errmsg
# Output: $errmsg - string containing human readable error msg
# Return: TRUE (valid) / FALSE (invalid)
sub valid_octets
{
	apierror("missing argument(s), expect 2 args") if( scalar(@_) < 2);
	my $ip  = shift;
	my $err = shift; #Reference

	my @addr = split(/\./, $ip);
	my $rc = TRUE;
	my $octet_count=0;

	foreach my $octet (@addr) {
		if( $octet !~ /^\d+$/ ) {
			$$err = get_error_msg(E_NONDIGIT_OCTET);
			prn_dbg("$$err") if($DEBUG or DBG_valid_octets);
			$rc = FALSE;
			last;
		}
		if( ($octet < 0) or ($octet > 255) ) {
			$$err = get_error_msg(E_OUTOFRANGE_OCTET);
			prn_dbg("$$err") if($DEBUG or DBG_valid_octets);
			$rc = FALSE;
			last;
		}
		$octet_count++;   #Counter instead of scalar(@addr) b/c of 192.168..1
	}

	#FIXME: if anything above fails, this will also fail, clobbering $$err
	if( $octet_count < 4 ) {
		$$err = get_error_msg(E_MISSING_OCTET);
		prn_dbg("$$err") if($DEBUG or DBG_valid_octets);
		$rc = FALSE;
	}

	return($rc);
}


#  Descr: Check to see if an IP is on a given network based on a given netmask
#         tmp = ip && netmask, ex. 192.168.1.32 && 255.255.255.0
#         if(tmp == network) then ip is on this network
#         else not on this network
#         Note, If all octets of IP are on all octets of the network ($cnt=4)
# Return: TRUE (on net) / FALSE (!on net)
sub address_on_network
{
	apierror("missing argument(s), expect 3 args") if( scalar(@_) < 3);
	my $ip      = shift;
	my $network = shift;
	my $netmask = shift;

	my $n_octets= 4;    # IPv4 uses 4 octets, ex. x.x.x.x
	my $cnt = 0;
	my @tmp_ip = ();

	my @ip   = split(/\./, $ip);
	my @netw = split(/\./, $network);
	my @mask = split(/\./, $netmask);

	prn_dbg("ip=($ip) network=($network/$netmask)") if($DEBUG 
	                                                or DBG_address_on_network);

	for(my $tmp=0, my $i=0; $i < $n_octets; $i++) {
		$tmp = int($ip[$i]) & int($mask[$i]); 

		 # increment if (tmp_ip_octet eq netw_octet) OR (netw_octet eq 0)
		$cnt++ if( (int($tmp) == int($netw[$i])) || (int($mask[$i] == 0)) );
	}	

	 # TRUE (on net) / FALSE (!on net)
	return( ($cnt == $n_octets)? TRUE : FALSE );
}


#  Descr: Increment an address for a given network
# Return: $next_ip (success) / undef (error)
#   Note: Returned IP address is in dotted-quad fmt, ex. "192.168.1.2"
sub increment_address
{
	apierror("missing argument(s), expect 3 args") if( scalar(@_) < 3);
	my $ip      = shift;
	my $network = shift;
	my $netmask = shift;
	my $errmsg;

	return(undef) if not defined($ip);      
	return(undef) if not defined($network);
	return(undef) if not defined($netmask);

	 #Ignoring error msg for now
	return(undef) if not valid_octets($ip, \$errmsg);
	return(undef) if not valid_octets($network, \$errmsg);
	return(undef) if not valid_octets($netmask, \$errmsg);

	my @addr = split(/\./, $ip);
	my @netw = split(/\./, $network);

	my @next_addr = increment_octets(3, $network, $netmask, @addr);
	my $next_ip = join('.', @next_addr);

	prn_dbg(" ip=($ip)  next_ip=($next_ip) ") if($DEBUG 
	                                             or DBG_increment_address);

	return( ($next_ip eq NETWORK_FULL)? undef : $next_ip );
}


#  Descr: Recursively increment address over octets, where octets
#         corresponds to dotted-decimal view, e.g., [0].[1].[2].[3].
#         The highest level octet (eg. [0]) is never increment.
#         The network/netmask limit the range of values to assign
#         based on the address_on_network() routine.
#
#  Input: $octet   - starting octet [zero-indexed], e.g. 0
#         $network - used along with netmask to determine when network's full
#         $netmask - used along with network to determine when network's full
#         @addr    - array with each field broken out, e.g. qw(192 168 1 2)
#
# Return: @addr w/ next IP (success) / @addr=qw(0 0 0 0) (error)
#
#   Note: The only real error case is when you run out of addresses
#         so we return the sentinel value of "0.0.0.0" (NETWORK_FULL) since 
#         we shouldn't ever assign that as a host IP address.
sub increment_octets
{
	apierror("missing argument(s), expect 4 args") if( scalar(@_) < 4);
	my $octet = shift;
	my $netw  = shift;
	my $mask  = shift; 
	my @addr  = @_;

	prn_dbg("octet[$octet] (".join('.',@addr).") ($netw/$mask)") if($DEBUG 
	                                                   or DBG_increment_octets);

	return(NETWORK_FULL) if($octet == 0); # Hit limit return "full" sentinel

	$addr[$octet] = ($addr[$octet] + 1) % 255;

	if( $addr[$octet] == 0 ) {
		 # Recurse to next octet
		@addr = increment_octets(($octet - 1), $netw, $mask, @addr);

		 # Increment current octet by 1 b/c of the rollover
		return(NETWORK_FULL) if(not defined($addr[$octet])); #FIXME: uninitialized value hack
		$addr[$octet] = ($addr[$octet] + 1) % 255;  
	}

	 # Only allow address to go out that are on our network/netmask
	return(NETWORK_FULL) if(not defined($addr[3])); #FIXME: uninitialized value hack
	if(not address_on_network(join('.',@addr), $netw, $mask)) {
		return(NETWORK_FULL);
	} else {
		return(@addr);
	}
}


#XXX: not work for calls from main(), so prn_dbg() not @EXPORT'ed
#     not a big deal since it's really only helpful internally
sub prn_dbg
{
	my $msg    = shift;

	my @caller = caller(1);   
	my $prefix = "DBG_" . $caller[3] . ":";  

	print "$prefix $msg\n";
}


# Simple hack to print offending caller and routine called incorrectly
sub apierror
{
	my $msg = shift;
	my $str;

	$str = "apiUsageError: " . (caller(1))[3] . " - $msg,";
	$str .= " called from - " . (caller(2))[3] . "\n";

	print STDERR $str;
	exit(1);
}


sub get_error_msg
{
	my $err = shift;
	my $msg = "Error: ";

	if( $err eq E_MISSING_OCTET ) { 
		$msg .= "missing octet in address";
	}
	elsif( $err eq E_NONDIGIT_OCTET ) {
		$msg .= "non-digit found in octet of address";
	}
	elsif( $err eq E_OUTOFRANGE_OCTET ) {
		$msg .= "out of range value in octet of address - valid range [1..254]";
	}
	elsif( $err eq E_MISC ) {
		$msg .= "miscellaneous error encountered in" . __PACKAGE__;
	}
	else {
		$msg .= "unknown error -- badness in".  __PACKAGE__;
	}

	return($msg);
}

1;
