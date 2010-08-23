#!/usr/bin/perl
# $Id: su-check.pl 7477 2008-09-27 03:57:38Z valleegr $
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use warnings;
use English '-no_match_vars';

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;
use OSCAR::FileUtils;

my $rc = SUCCESS;

my $l = "# These entries are managed by SIS, please don't modify them.";
if (OSCAR::FileUtils::line_in_file ($l, "/etc/hosts") != -1) {
    print " ----------------------------------------------\n";
    print "  $0 \n";
    print " Your /etc/hosts file has references to OSCAR compute node\n";
    print " from a deprecated version of OSCAR. Please remove these entries,\n";
    print " they are right after:\n \"$l\"\n";

    $rc = FAILURE;
}

exit ($rc);
