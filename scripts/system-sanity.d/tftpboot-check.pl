#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.

use warnings;
use English '-no_match_vars';
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::OCA::OS_Detect;

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = FAILURE;

my $os = OSCAR::OCA::OS_Detect::open();
my $distro_id = $os->{distro} . "-" . $os->{distro_version} . "-" . 
                $os->{arch};

# We first do some very basic tests
if ( ! -d "/tftpboot" && 
     ! -d "/tftpboot/distro") {
     print " -------------------------------------\n";
     print " Directories for tftpboot do not exist\n";
     print " -------------------------------------\n";
     exit ($rc);
}
 
# Then we check if /tftpboot have all we need for the local distro
my $file = "/tftpboot/distro/" . $distro_id . ".url";
my $dir = "/tftpboot/distro/" . $distro_id;
if ( ! -f $file || ! -d $dir ) {
    print " ------------------------------------------------------------\n";
    print " Impossible to find a local or online repository in /tftpboot\n".
          " for the distro $distro_id\n";
    print " ------------------------------------------------------------\n";
    exit ($rc);
}

$rc = SUCCESS;
exit ($rc);

