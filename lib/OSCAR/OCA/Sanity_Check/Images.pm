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
# $Id: Images.pm 5913 2007-06-15 02:45:52Z valleegr $
#
# This script checks images, i.e., if SIS and OSCAR databased and the
# file system are synchronized.
#

package OCA::Sanity_Check::Images;

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use OSCAR::Utils;
use OSCAR::OCA::Debugger;
use OSCAR::ImageMgt qw ( get_list_corrupted_images );
use Data::Dumper;
use Carp;

sub open {
    oca_debug_section ("Sanity_Check::Images\n");
    my @corrupted_images = get_list_corrupted_images();

    foreach my $corrupted_image (@corrupted_images) {
        print "Corrupted image: $corrupted_image->{'name'}\n";
        print "Image status:\n";
        print "\tODA: $corrupted_image->{'oda'}\n";
        print "\tSIS: $corrupted_image->{'sis'}\n";
        print "\tFS: $corrupted_image->{'fs'}\n";
    }

    return 1;
}

1;
