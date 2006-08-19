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
my $ssh_config = `grep \"PermitRootLogin\" /etc/ssh/sshd_config | awk ' { print \$2} '`;
chomp ($ssh_config);
if ( $ssh_config eq "yes" ) {
	$rc = SUCCESS;
} else {
	print " ----------------------------------------------\n";
	print "  $0 \n";
	print "  Option PermitRootLogin in /etc/ssh/sshd_config should be \'yes\'\n";
	print "  Current value is \'$ssh_config\'\n";
	print " ----------------------------------------------\n";

	$rc = FAILURE;  
}

exit($rc);
