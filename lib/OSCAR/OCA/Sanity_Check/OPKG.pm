#!/usr/bin/env perl
#
# Copyright (c) 2007 Oak Ridge National Laboratory.
#                    Geoffroy Vallee <valleegr@ornl.gov>
#                    All rights reserved.
#
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id: OPKG.pm 5913 2007-06-15 02:45:52Z valleegr $
#
# This file check the status of OPKGs. For that, we check the list of OPKGs:
#   - shipped with OSCAR,
#   - available via the default package set,
#   - installable via data in the database.
# Note that the only really error is when the list of OPKGs in the default
# package set does not match the list of installable OPKGs.

package OCA::Sanity_Check::OPKG;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::PackageSet qw ( get_list_opkgs_in_package_set );
use OSCAR::Opkg qw ( get_list_opkg_dirs );
use OSCAR::Utils qw ( print_array );
use OSCAR::OCA::Debugger;
use OSCAR::Database;
use Carp;

sub open
{
    oca_debug_section ("Sanity_Check::OPKG\n");
    my $DEFAULT = "Default";
    my %options = ();
    my @errors = ();

    # First we list OPKGs available into $(OSCAR_HOME)/packages
    my @dirs = get_list_opkg_dirs ();
    print "OPKGs shipped with OSCAR: \n";
    print_array (@dirs);

    # Second we list OPKGs in the Default package set
    my @default_opkgs = get_list_opkgs_in_package_set ($DEFAULT);
    print "OPKGs in the default package set: \n";
    print_array (@default_opkgs);

    # if the OPKGs in the default package set do not match the list of OPKGs
    # shipped with OSCAR, we print a warning. That may be normal, it depends
    # on the OSCAR status for local Linux distribution
    if (@dirs ne @default_opkgs) {
        print "WARNING!!! The default package set for your distro does NOT ".
              "include all available OPKGs. That may be normal but double ".
              "check\n";
    }

    # We get the list of installable OPKGs
    my @installable_packages = ();
    my @tmp = ();
    set_groups_selected($DEFAULT,\%options,\@errors);
    get_selected_group_packages(\@tmp,\%options,\@errors);
    foreach my $package_ref (@tmp) {
        my $package_name = $$package_ref{package};
        push (@installable_packages, $package_name);
    }
    print "Installable OPKGs: \n";
    print_array (@installable_packages);

    # if the list of installable OPKGs does not match the list of OPKGs 
    # available in the default package set, something is wrong!! the OSCAR
    # initialization assumes that all OPKGs in the default package set are
    # installable.
    if (@default_opkgs ne @installable_packages) {
        carp ("ERROR: the list of installable OPKGs does not match the list ".
              "of OPKGs available via the default package set!!!");
        return -1;
    }

    oca_debug_section ("Sanity_Check::OPKG, Done!\n");

    return 1;
}

1;
