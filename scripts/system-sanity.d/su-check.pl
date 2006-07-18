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

if ( ($UID == 0) and ($ENV{USER} eq "root") ) {
	$rc = SUCCESS;

} else {
	print " ----------------------------------------------\n";
	print "  $0 \n";
	print "   UID=(" . $UID       . ") \t should be \'0\'\n";
	print "  USER=(" . $ENV{USER} . ") \t should be \'root\'\n";
	print " ----------------------------------------------\n";

	$rc = FAILURE;  
}

exit($rc);
