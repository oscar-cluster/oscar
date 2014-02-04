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

# We first test if the file /etc/ssh/sshd_config exists or not.
# If the file does not exist, it should be because it is the first time
# OSCAR runs, so we skip the sanity check
# If the file exists, we check the configuration.
if (!-e "/etc/ssh/sshd_config") {
    print "FYI the file does /etc/ssh/sshd_config not exists, it is not \
possible to check the sshd configuration. It is normal, most probably \
your Linux distribution does not install sshd by default, OSCAR will do it \
for you.";
    $rc = SUCCESS;
    }
else {
    my $ssh_config = `grep \"PermitRootLogin\" /etc/ssh/sshd_config | grep -v \"^\\s\*\#\" | awk ' { print \$2} '`;
    chomp ($ssh_config);
    if ( $ssh_config eq "yes" ) {
    	$rc = SUCCESS;
    } else {
    	print " ----------------------------------------------\n";
    	print "  $0 \n";
    	print "  Option PermitRootLogin in /etc/ssh/sshd_config should be \'yes\'\n";
    	print "  Current value is \'$ssh_config\'\n";
        print "  For users that compiled their own version of ssh, please be sure \
the configuration file matches the ssh configuration. The configuration file is \
our only way to check the ssh configuration\n";
    	print " ----------------------------------------------\n";

    	$rc = FAILURE;  
    }
}

exit($rc);
