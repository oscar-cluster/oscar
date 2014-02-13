#!/usr/bin/perl
# $Id$
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

my $rc = FAILURE;

if (! -f "/usr/sbin/selinuxenabled" ) {
        # We cannot find the file to test selinux, we assume selinux is 
        # not installed
        $rc = SUCCESS;
} else {
        if ( system("/usr/sbin/selinuxenabled") ) {
	        $rc = SUCCESS;

        } else {
	        print " ----------------------------------------------\n";
        	print "  $0 \n";
        	print "  SELinux is enabled, please deactivate it editing\n";
        	print "  /etc/selinux/config\n";
        	print " ----------------------------------------------\n";

        	$rc = FAILURE;  
        }
}

exit($rc);
