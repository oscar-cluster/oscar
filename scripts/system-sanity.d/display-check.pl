#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.

use warnings;
use English '-no_match_vars';
use lib "$ENV{OSCAR_HOME}/lib";
use POSIX;

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = SUCCESS;

# No need to check DISPLAY env variable if we're not using the GUI
if (!defined$ENV{OSCAR_UI} || $ENV{OSCAR_UI} ne "gui") {
    exit ($rc);
}

if ( not defined $ENV{DISPLAY} ) {
    print " ------------------------------------------------------------\n";
    print " ERROR: Your \"DISPLAY\" environment variable is not set,\n";
    print " probably indicating that you are not running in an X windows\n";
    print " environment.\n";
    print " OSCAR requires that you run the installer in an X windows\n";
    print " environment.\n";
    print " ------------------------------------------------------------\n";
    $rc = FAILURE;
}

exit ($rc);
