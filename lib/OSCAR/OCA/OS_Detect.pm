#
# Copyright (c) 2005 The Trustees of Indiana University.  
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OSCAR::OCA::OS_Detect;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::OCA;

#
# Exports
#

@EXPORT = qw($OS_Detect);

#
# Globals
#

our $OS_Detect;

#
# Subroutine to open the OS_Detect framework
#

sub open {
    my %opt = @_;

    my $comps = OSCAR::OCA::find_components("OS_Detect");

    # Did we find one and only one?

    if (undef == $comps) {
        # If we get undef, then find_components() already printed an
        # error, and we decide that we want to die
        die "Cannot continue";
    } elsif (scalar(@$comps == 0)) {
        print "Could not find an OS_Detect component for this system!\n";
        die "Cannot continue";
    } elsif (scalar(@$comps) > 1) {
        print "Found more than one OS_Detect component for this system!\n";
        foreach my $comp (@$comps) {
            print "\t$comp\n";
        }
    }

    # Yes, we found some components. Check which one returns a valid id
    # hash.

    my $ret = 0;
    foreach my $comp (@$comps) {
	my $str = "\$OS_Detect->{query} = \\&OCA::OS_Detect::@$comps[0]::query(\%opt)";
	eval $str;
	if (ref($OS_Detect->{query}) eq "HASH") {
	    print "Found component that fits: $comp\n";
	    $ret = 1;
	    last;
	}
    }
    return $ret;
}

1;
