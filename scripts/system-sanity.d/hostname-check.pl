#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.

use warnings;
use English '-no_match_vars';
use lib "$ENV{OSCAR_HOME}/lib";
use POSIX;

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = SUCCESS;

my $hostname = (uname)[1];
if ($hostname eq "") {
    $rc = FAILURE;
} else {
    my ($shorthostname) = split(/\./,$hostname,2);
    my $dnsdomainname = `dnsdomainname`;
    chomp($dnsdomainname);
    chomp ($hostname);

    if ($shorthostname eq "localhost") {
        $rc = FAILURE;
    }
    if ($hostname eq "localhost.localdomain") {
        $rc = FAILURE;
    }
}

if ( $rc eq FAILURE ) {
    print " ----------------------------------------------\n";
    print "  $0 \n";
    print "  Hostname not correct \n";
    print " ----------------------------------------------\n";
}

exit($rc);
