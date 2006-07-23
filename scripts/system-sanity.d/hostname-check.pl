#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.

use warnings;
use English '-no_match_vars';
use lib "$ENV{OSCAR_HOME}/lib";

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = FAILURE;

my $hostname = `hostname`;
chomp ($hostname);
print "Hostname = $hostname\n";

if ( $hostname ne "localhost" && $hostname ne "") {
    $rc = SUCCESS;
} else {
    print " ----------------------------------------------\n";
    print "  $0 \n";
    print "  Hostname not correct \n";
    print " ----------------------------------------------\n";

    $rc = FAILURE;
}

exit($rc);
