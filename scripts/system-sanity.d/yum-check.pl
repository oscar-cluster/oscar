#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2008 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#
# This script checks the yum configuration file.

use warnings;
use English '-no_match_vars';
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::ConfigFile;

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = SUCCESS;

if ( -f "/etc/yum.conf" ) {
    my $value = get_value ("/etc/yum.conf", "gpgkey");
    if ($value == 1) {
        print "----------------------------------------------\n";
        print " ERROR: Yum configuration is invalid\n";
        print " The gpgkey is set to 1, it will be impossible\n";
        print " to install OSCAR packages.\n";
        print " Please, set the gpgkey to 1 (/etc/yum.conf).\n";
        print "----------------------------------------------\n";
        $rc = FAILURE;
    }
}

exit ($rc);
