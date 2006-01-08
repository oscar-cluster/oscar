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
        foreach my $comps (@$comps) {
            print "\t$comps\n";
        }
        die" Cannot continue";
    }

    # Yes, we only found one.  Suck its function pointers into the
    # global $OS_Detect hash reference.

    my $str = "\$OS_Detect->{query} = \\&OCA::OS_Detect::@$comps[0]::query";
    eval $str;

    # Happiness -- tell the caller that all went well.

    1;
}

1;
