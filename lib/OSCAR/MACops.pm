package OSCAR::MACops;

# Copyright (c) 2004 	The Board of Trustees of the University of Illinois.
#                     	All rights reserved.
#			Jason Brechin <brechin@ncsa.uiuc.edu>

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

use strict;
use Carp;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Logger;
use OSCAR::Database;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw (  save_to_file
                load_from_file
                verify_mac 
	     );

# save_to_file - Saves a list of MACs to a file in an appropriate format
# Args:  $filename, @list_of_macs
# Returns nothing
sub save_to_file {
    my $file = shift;
    my @macs = @_;
    open(OUT,">$file") or croak "Couldn't open file: $file for writing";
    print OUT "# Saved OSCAR MAC Addresses\n";
    foreach my $mac ( @macs ) {
        print OUT $mac, "\n";
    }
    close(OUT);
}

# load_from_file - Loads a list of MACs from a file and returns array of macs
# Args:  $filename
# Returns array of loaded MACs that pass verification
sub load_from_file {
    my $file = shift;
    my @macs;
    open(IN,"<$file") or croak "Couldn't open file: $file for reading";
    while(<IN>) {
        if(/^\s*\#/) {
            next;
        }
        if( my $mac = verify_mac($_) ) {
            push @macs, $mac;
        }
    }
    close(IN);
    return @macs;
}

# verify_mac - Verifies a MAC address and, if possible and necessary, will 
# 	       reformat to match our format requirements
# Args:  $mac, ($debug=0)
# Returns formatted MAC address or nothing
sub verify_mac {
    my $mac = shift;
    chomp($mac);
    my $debug = shift;
    if ( $mac =~ /^([a-fA-f0-9]{2}:){5}[a-fA-F0-9]{2}$/ ) {
        if ( $debug ) { print "$mac is fully formed\n"; }
        return $mac;
    } elsif ( $mac =~ /^[a-fA-F0-9]{12}$/ ) {
        if ( $debug ) { print "$mac has no colons \n"; }
        return join(':', ( $mac =~ /(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)(\w\w)/ ));
    } else {
        warn ( "$mac is not formed correctly!\n" );
    }
    return;
}

