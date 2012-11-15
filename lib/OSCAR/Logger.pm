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
#   Copyright (c) 2007-2008 Oak Ridge National Laboratory
#                           Geoffroy Vallee <valleegr@ornl.gov>
#                           All rights reserved.

use strict;
use Carp;
use vars qw($VERSION @EXPORT);
use base qw(Exporter);

@EXPORT = qw(oscar_log_section oscar_log_subsection verbose vprint);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

my $verbose = $ENV{OSCAR_VERBOSE};

################################################################################
# Simple routine to output a "section" title to stdout.                        #
#                                                                              #
# Input: String to display.                                                    #
# Return: None.                                                                #
################################################################################
sub oscar_log_section ($) {
    my $title = shift;

    print "
=============================================================================
== $title
=============================================================================

";
}


################################################################################
# Simple routine to output a "subsection" title to stdout.                     #
#                                                                              #
# Input: the string to display.                                                #
# Return: None.
################################################################################
sub oscar_log_subsection ($) {
    my $title = shift;

    if ($ENV{OSCAR_VERBOSE}) {
        print "--> $title\n";
    }
}


sub verbose {
    print join " ", @_;
    print "\n";
}

sub vprint {
    print @_ if ($verbose || $ENV{OSCAR_VERBOSE});
}

sub print_error_strings ($) {
    my $passed_errors_ref = shift;
    my @error_strings = ();
    my $error_strings_ref = ( defined $passed_errors_ref && 
                  ref($passed_errors_ref) eq "ARRAY" ) ?
                  $passed_errors_ref : \@error_strings;

    if ( defined $passed_errors_ref 
         && ! ref($passed_errors_ref) 
         && $passed_errors_ref ) {
        warn shift @$error_strings_ref while @$error_strings_ref;
    }
    $error_strings_ref = \@error_strings;
}

################################################################################
# Setup a log file for a given process.
#
# Input: Absolute path of the log file.
# Return: 0 if the log file can be set correctly, -1 else.
################################################################################
sub init_log_file ($) {
    my $log_file = shift;

    # Setup to capture all stdout/stderr
    require File::Basename;
    my $oscar_log_dir = File::Basename::dirname ($log_file);
    if (! -d $oscar_log_dir ) {
        print "$oscar_log_dir does not exist, we create it\n";
        mkdir ($oscar_log_dir);
    }

    # EF: Fix for bug #244: multiple oscarinstall.log files
    # The current (and latest) log file is oscarinstall.log. Old log files
    # get a number appended (eg. oscarinstall.log_27), starting with _1
    # and increasing with each new invocation of install_cluster.
    # Date stamp added to output.
    if (-e $log_file) {
        my $indx = 1;
        # more old logs around?
        my @ologs = glob("$log_file"."_*");
        @ologs = map { if (/_(\d+)$/) { $1 } } @ologs;
        @ologs = sort { $a <=> $b; } @ologs;
        if (@ologs) {
            $indx = $ologs[$#ologs] + 1;
        }
        !system("mv $log_file $log_file"."_$indx")
        or (carp "Could not rename $log_file : $!", return -1);
    }

    if (!open (STDOUT,"| tee $log_file") || !open(STDERR,">&STDOUT")) {
        (carp("ERROR: Cannot tee stdout/stderr into the OSCAR logfile: ".
        "$log_file\n\nAborting the install.\n\n"), return -1);
    }

    if (defined ($ENV{OSCAR_VERBOSE})) {
        print ("Verbosity: $ENV{OSCAR_VERBOSE}\n");
    } else {
        print ("Verbosity: 0\n");
    }

    return 0;
}

1;

__END__

=head1 Exported functions:

=over 4

=item init_log_file

Setup a log file for a given process.

=back

=cut
