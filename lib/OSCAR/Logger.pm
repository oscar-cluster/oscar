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
use OSCAR::Env;
use OSCAR::LoggerDefs;
use Switch 'Perl5', 'Perl6';

our @EXPORT = qw(
             oscar_log_section
             oscar_log_subsection
             oscar_log_message
             oscar_log_error
             oscar_log
             verbose
             vprint
             init_log_file
             update_log_file
            );

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);


################################################################################
# Simple routine to output a "section" title to stdout.                        #
#                                                                              #
# Input: String to display.                                                    #
# Return: None.                                                                #
################################################################################
sub oscar_log_section ($) {
    my $title = shift;
    oscar_log(3, SECTION, "$title");
}


################################################################################
# Simple routine to output a "subsection" title to stdout.                     #
#                                                                              #
# Input: the string to display.                                                #
# Return: None.                                                                #
################################################################################
sub oscar_log_subsection ($) {
    my $title = shift;
    oscar_log(3, SUBSECTION, "$title");
}

################################################################################
## Exported function to print a messsage if verbosity is higher than min       #
##                                                                             #
## Inputs:  $verbose  min verbosity required to have the message displayed     #
##          $message  The message itself                                       #
##                                                                             #
## Outputs: none                                                               #
################################################################################
sub oscar_log_message ($$) {
    my($verbose, $message) = @_;
    print "$message" if($verbose <= $OSCAR::Env::oscar_verbose);
}

################################################################################
## Exported function to print a messsage if verbosity is higher than min       #
##                                                                             #
## Inputs:  $verbose  min verbosity required to have the message displayed     #
##          $message  The message itself                                       #
##                                                                             #
## Outputs: none                                                               #
################################################################################
sub oscar_log_error ($$) {
    my($verbose, $message) = @_;
    if ($OSCAR::Env::oscar_verbose >= 10) {
        carp "$message"; # in --debug, we use carp to display the message.
    } else {
        print "$message" if($verbose <= $OSCAR::Env::oscar_verbose);
    }
}

################################################################################
## Exported function to print all kind of msg if verbosity is higher than min  #
##                                                                             #
## Inputs:  $verbose  min verbosity required to have the message displayed     #
##          $type     the type of messages (ERROR, INFO, ...)                  #
##                    NONE is used for no prefix                               #
##          $message  The message itself                                       #
##                                                                             #
## Outputs: none                                                               #
################################################################################
sub oscar_log ($$$) {
    my($verbose, $type, $message) = @_;

    # 1st: Doing formatting given the type of message.
    given ($type) {
        when (SECTION) {
            $message = "\n================================================================================\n" . 
                         "== $message\n" .
                         "================================================================================\n";
        }
        when (SUBSECTION) {
            my $length = length $message;
            my $prepend_count = int((80-$length)/2) -1;
            my $append_count = 80-$prepend_count-$length-2;
            $message = "-" x $prepend_count . " $message " . "-" x $append_count . "\n";
        }
        when (NONE) {
            $message = "$message\n";
        }
        default {
            $message = "[$type] $message\n";
        }
    }

    # Now printing the message if conditions are met.
    if ($OSCAR::Env::oscar_verbose >= 10) {
        if ($type eq ERROR) {
            carp "$message"; # in --debug (log level 10), we use carp to display errors.
        } else {
            print "$message";
        }
    } else {
        print "$message" if($verbose <= $OSCAR::Env::oscar_verbose);
    }
}

sub verbose {
    print join " ", @_;
    print "\n";
}

sub vprint {
    print @_ if ($OSCAR::Env::oscar_verbose);
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
        oscar_log(6, ACTION, "$oscar_log_dir does not exist, we create it\n");
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
        or (oscar_log(5, ERROR, "Could not rename $log_file : $!"), return -1);
    }

    if (!open (STDOUT,"| tee $log_file") || !open(STDERR,">&STDOUT")) {
        (oscar_log(5, ERROR, "Cannot tee stdout/stderr into the OSCAR logfile: ".
        "$log_file\n\nAborting the install.\n"), return -1);
    }

    oscar_log(1, INFO, "Verbosity: ". $OSCAR::Env::oscar_verbose);
#    if (defined ($ENV{OSCAR_VERBOSE})) {
#        print ("Verbosity: $ENV{OSCAR_VERBOSE}\n");
#    } else {
#        print ("Verbosity: 0\n");
#    }

    return 0;
}

################################################################################
# Update the existing log file for a given process.
# This is added for sync_files log to prevent sync_files from creating useless 
# log files with redundant log messages.
#
# Input: Absolute path of the log file.
# Return: 0 if the log file can be set correctly, -1 else.
################################################################################
sub update_log_file ($) {
    my $log_file = shift;

    oscar_log(5, INFO, "Updating log file ($log_file).");
    # Setup to capture all stdout/stderr
    require File::Basename;
    my $oscar_log_dir = File::Basename::dirname ($log_file);
    if (! -d $oscar_log_dir ) {
        oscar_log(6, INFO, "$oscar_log_dir does not exist.");
        oscar_log(6, ACTION, "Creating $oscar_log_dir directory.");
        mkdir ($oscar_log_dir);
    }

    if (!open (STDOUT,"| tee -a $log_file") || !open(STDERR,">&STDOUT")) {
        (oscar_log(5, ERROR, "Cannot tee stdout/stderr into the OSCAR logfile: ".
        "$log_file\n\nAborting the install.\n"), return -1);
    }

    my $timestamp = `date +\"%Y-%m-%d-%k-%M-%m\"`;
#    print ">> $timestamp";
    oscar_log(1, INFO, "Timestamp: $timestamp\n");
    oscar_log(1, INFO, "Verbosity: ". $OSCAR::Env::oscar_verbose);
#    if (defined ($ENV{OSCAR_VERBOSE})) {
#        print ("Verbosity: $ENV{OSCAR_VERBOSE}\n");
#    } else {
#        print ("Verbosity: 0\n");
#    }

    oscar_log(5, INFO, "Successfully updated log file ($log_file).");
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
