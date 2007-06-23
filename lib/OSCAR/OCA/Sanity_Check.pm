#
# Copyright (c) 2007 Oak Ridge National Laboratory
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id: Sanity_Check.pm 5877 2007-06-07 22:00:37Z dikim $
#

package OSCAR::OCA::Sanity_Check;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::OCA;

#
# Exports
#

#
# Globals
#
my $verbose = 1 if $ENV{OCA_DEBUG} eq "y";

#
# Subroutine to open the Check_Repository framework
#

sub open {
    # we open all the components we find
    my $comps = OSCAR::OCA::find_components("Sanity_Check");
    if (scalar(@$comps) == 0) {
        print "No sanity_check component has been found\n";
    } else {
        print "Components found: @$comps\n" if $verbose > 0;
    }
    my $str;
    my $comp;

    foreach $comp (@$comps) {
      # We call each component we found
      print "Executing component: $comp\n" if $verbose > 0;
      $str = "\&OCA::Sanity_Check::" . $comp . "::open()";
      eval $str;
    }

    1;
    
}


1;
