package OSCAR::Logger;

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

#   Copyright 2002 Jeffrey M. Squyres <jsquyres@lam-mpi.org>

use strict;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw(oscar_log_section oscar_log_subsection verbose vprint);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

my $verbose = $ENV{OSCAR_VERBOSE};

#############################################################################
#
# Simple routine to output a "section" title to stdout
#
#############################################################################

sub oscar_log_section {
    my $title = shift;

    print "
=============================================================================
== $title
=============================================================================

";
}


#############################################################################
#
# Simple routine to output a "subsection" title to stdout
#
#############################################################################

sub oscar_log_subsection {
    my $title = shift;

    print "--> $title\n"
}


sub verbose {
    print join " ", @_;
    print "\n";
}

sub vprint {
    print @_ if ($verbose);
}



1;
