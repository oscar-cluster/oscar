#!/usr/bin/perl
#
# Copyright (c) 2006 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# This script check if the /etc/apt/sources.list on Debian is a minimum correct
# (with at least one entry.

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use warnings;
use English '-no_match_vars';

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = WARNING;

sub check_apt_entry {
        my $cmd = "cat /etc/apt/sources.list | sed -e '/^deb /!d'";
        my $ret = `$cmd`;
        if (length($ret) > 0 ) {
                return 0;
        }
        return -1;
}

if (! -f "/etc/apt/sources.list" ) {
	# the file /etc/debian_version does not exist, it is not a Debian based
	# distro, we stop here.
	$rc = SUCCESS;
} elsif (check_apt_entry() == 0) {
	
	$rc = SUCCESS; 
}

if ($rc eq WARNING) {
	print " ----------------------------------------------\n";
        print " $0 \n";
        print " Impossible to find a valid entry in your \
		/etc/apt/sources.list file.\n";
        print " Please update it to point to a valid Debian repository.\n";
        print " ----------------------------------------------\n";
}

exit ($rc);


