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

#
# Exports
#

@EXPORT = qw($RM_Detect);

#
# Globals
#

our $RM_Detect;

###############################################################################
# Subroutine to open the RM_Detect framework.                                 #
# Input:  None.                                                               #
# Return: Return the id the resource manager. A "None" resource manager is    #
#         available and used if no real resource manager is found.            #
#         Note that the id is a hash and that the usefull string is in the    #
#         "rm" key.                                                           #
###############################################################################
sub open {
    my $comps = OSCAR::OCA::find_components("RM_Detect");

    # Did we find one and only one?
    my $comp;

    # No framework components found or only the None one has been found
    if (scalar(@$comps) == 0) {
        die "ERROR: Could not find any component for this RM_Detect ".
            "framework!\n";
    } else {
        # We should have found at least 1 component: the None component
        # So: - if we have one component only and it is not the None one, this
        #       is an error
        #     - if we have two components, we skip the None one.
        #     - if we have more than two components, this is not normal, we 
        #       should not have more than 1 resource manager.
        if (scalar(@$comps) == 1) {
            if (@$comps[0] ne "None") {
                die ("ERROR: Only one resource manager has been found and it ".
                     "is not the \"None\" one which should be available by ".
                     "default");
            } else {
                $comp = @$comps[0];
            }
        } elsif (scalar(@$comps) == 2) {
            if (@$comps[0] eq "None" && @$comps[1] eq "None") {
                die "ERROR: We detected two resource managers but they are ".
                    "both the \"None\" one";
            } else {
                if (@$comps[0] eq "None") {
                    $comp = @$comps[1];
                } else {
                    $comp = @$comps[0];
                }
            }
        } else {
            die "ERROR: we found more than one resource manager this is not
                 normal!";
        }
    }

    # Yes, we only found one.  Suck its function pointers into the
    # global $RM_Detect hash reference.

    my $ret = undef;
    my $str = "\$ret = \&OCA::RM_Detect::".$comp."::query()";
    eval $str;
    die "ERROR: unable to query the module $comp" if (!defined($ret));

    # Happiness -- tell the caller that all went well.

    return $ret;
}

1;
