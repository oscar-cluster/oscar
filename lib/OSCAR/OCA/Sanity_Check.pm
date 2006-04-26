#!/usr/bin/perl

package OSCAR::OCA::Sanity_Check;

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use OSCAR::OCA;

#
# Exports
#

@EXPORT = qw($Sanity_Check);

#
# Globals
#

our $Sanity_Check;

#
# Subroutine to open the Check_Repository framework
#

sub open {
    # we open all the components we find
    my $comps = OSCAR::OCA::find_components("Sanity_Check");

    my $n; 
    for ($n = @$comps; $n > 0; $n--) {
      # We call each component we found
      my $str = "\&OCA::Sanity_Check::" . @$comps[$n-1] . "::open()";
      eval $str;
    }

    1;
    
}

1;
