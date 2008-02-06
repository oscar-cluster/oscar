#!/usr/bin/perl
# $Id$
#
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.

use warnings;
use English '-no_match_vars';
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::PackagePath;
use warnings "all";

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = FAILURE;

my $os = OSCAR::PackagePath::distro_detect_or_die();
if (!defined ($os)) {
    die "ERROR: unsupported Linux distribution\n";
}
my $distro_id = $os->{distro} . "-" . $os->{distro_version} . "-" . 
                $os->{arch};

# Step 1: we do some very basic tests
if ( ! -d "/tftpboot" && 
     ! -d "/tftpboot/distro") {
     print " --------------------------------------------\n";
     print " ERROR: Directories for tftpboot do not exist\n";
     print " --------------------------------------------\n";
     exit ($rc);
}
 
# Step 2: we check if /tftpboot have all we need for the local distro
# Two cases: we use a local pool or an online pool
my $file = "/tftpboot/distro/" . $distro_id . ".url";
my $dir = "/tftpboot/distro/" . $distro_id;
if ( ! -f $file && ! -d $dir ) {
    print " ---------------------------------------------------------\n";
    print " ERROR: Impossible to find a local or online repository in\n";
    print " /tftpboot for the distro $distro_id\n";
    print " ---------------------------------------------------------\n";
    exit ($rc);
}

# Step 3: we check if there are empty local pools
$dir = "/tftpboot/distro/";
opendir(DIR, "$dir") or die "Error: $! - \'$dir\'";
my @subdirs = readdir (DIR);
closedir(DIR);

foreach my $subdir (@subdirs) {
    if ($subdir eq "." || $subdir eq "..") {
        next;
    }
    $subdir = $dir . $subdir;
    # We skip local files
    if (-f "$subdir") {
        next;
    }
    # Do we have rpms in that directory?
    my @files = glob("$subdir/*.rpm");
    if (scalar(@files) == 0) {
        # If no do we have debian packages?
        @files = glob("$subdir/*.deb");
        if (scalar(@files) == 0) {
            print " -------------------------------------------------------\n";
            print " ERROR: it seems you have empty local repositories, \n";
            print " i.e., a local repository does not have any binary \n";
            print " package. The empty local repository is: $subdir.\n";
            print " Please populate the local pool or delete the directory.\n";
            print " -------------------------------------------------------\n";
            exit ($rc);
        }
    }
}

$rc = SUCCESS;
exit ($rc);

