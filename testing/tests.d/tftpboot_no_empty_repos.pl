#!/usr/bin/perl -w
#############################################################################
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#   Copyright (c) 2006 Oak Ridge National Laboratory.
#                      All rights reserved.
#   Copyright (c) 2006 Geoffroy Vallee
#                      All rights reserved.
#   Copyright (c) 2013-2014 CEA - Commissariat a l'Energie Atomique et
#                            aux Energies Alternatives
#                      All rights reserved.
#   Copyright (c) 2013-2014 Olivier LAHAYE <olivier.lahaye@cea.fr>
#                      All rights reserved.
#
# $Id: $
#
#############################################################################

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use warnings;
use English '-no_match_vars';
use OSCAR::OCA::OS_Detect;
use warnings "all";

# NOTE: Use the predefined constants for consistency!
use OSCAR::SystemSanity;

my $rc = FAILURE;

my $os = OSCAR::OCA::OS_Detect::open();
if (!defined ($os)) {
    die "ERROR: unsupported Linux distribution\n";
}
my $distro_id = $os->{distro} . "-" . $os->{distro_version} . "-" . 
                $os->{arch};

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
