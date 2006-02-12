#
# Copyright (c) 2005 Bernard Li <bli@bcgsc.ca>
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $HEADER$
#

package OSCAR::OCA::RM_Detect;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::OCA;
use Data::Dumper;

#
# Exports
#

@EXPORT = qw($RM_Detect);

#
# Globals
#

our $RM_Detect;

#
# Subroutine to open the RM_Detect framework
#

sub open {
    my $comps = OSCAR::OCA::find_components("RM_Detect");

    # Did we find one and only one?

    if (scalar(@$comps == 0)) {
        # Should never get here because it should default to None.pm if nothing is found
        print "Could not find an rm-detect component for this system!\n";
        die "Cannot continue";
    } elsif (scalar(@$comps) > 1) {
        # We don't want None.pm to be selected
	if (grep($comps, "None")) {
	    my $count = 0;
	    for (@$comps) {
	        if ($_ eq "None") {
		    splice (@$comps, $count, 1);
                }
	        $count++;
            }
	    # If even after None.pm has been removed, we still have more than one, we have
            # a problem
	    if (scalar(@$comps) > 1) {
	        print "Found more than one rm-detect component for this system!\n";
		die "Cannot continue";
            }
	} else {
            print "Found more than one rm-detect component for this system!\n";
            die "Cannot continue";
	}
    }

    # Yes, we only found one.  Suck its function pointers into the
    # global $RM_Detect hash reference.

    my $str = "\$RM_Detect->{query} = \\&OCA::RM_Detect::@$comps[0]::query";
    eval $str;

    # Happiness -- tell the caller that all went well.

    1;
}

1;
