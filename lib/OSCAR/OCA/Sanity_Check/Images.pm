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

use strict;
use lib "$ENV{OSCAR_HOME}/lib";
use OSCAR::Utils;
use OSCAR::OCA::Debugger;
use Data::Dumper;
use Carp;

sub open {
    oca_debug_section ("Sanity_Check::Images\n");
    my $sis_cmd = "/usr/bin/si_lsimage";
    my @sis_images = `$sis_cmd`;

    #We do some cleaning...
    # We remove the three useless lines of the result
    for (my $i=0; $i<3; $i++) {
    	shift (@sis_images);
    }
    # We also remove the last line which is an empty line
    pop (@sis_images);
    # Then we remove the return code at the end of each array element
    # We also remove the 2 spaces before each element
    foreach my $i (@sis_images) {
    	chomp $i;
    	$i = substr ($i, 2, length ($i));
    }

    # The array is now clean, we can print it
    print "List of images in the SIS database: ";
    print_array (@sis_images);

    my @tables = ("Images");
    my @oda_images = ();
    my @res = ();
    my $cmd = "SELECT Images.name FROM Images";
    if ( OSCAR::Database::single_dec_locked( $cmd,
    						"READ",
						\@tables,
						\@res,
						undef) ) {
	# The ODA query returns a hash which is very unconvenient
	# We transform the hash into a simple array
	foreach my $elt (@res) {
	    # It seems that we always have an empty entry, is it normal?
	    if ($elt->{name} ne "") {
	        push (@oda_images, $elt->{name});
	    }
	}
	print "List of images in ODA: ";
	print_array (@oda_images);
    } else {
    	die ("ERROR: Cannot query ODA\n");
    }

    # We get the list of images from the file system
    my $sis_image_dir = "/var/lib/systemimager/images";
    my @fs_images = ();
    die ("ERROR: The image directory does not exist ".
         "($sis_image_dir)") if ( ! -d $sis_image_dir );
    opendir (DIRHANDLER, "$sis_image_dir")
        or die ("ERROR: Impossible to open $sis_image_dir");
    foreach my $dir (sort readdir(DIRHANDLER)) {
        if ($dir ne "." 
            && $dir ne ".."
            && $dir ne "ACHTUNG"
            && $dir ne "DO_NOT_TOUCH_THESE_DIRECTORIES"
            && $dir ne "CUIDADO"
            && $dir ne "README") {
            push (@fs_images, $dir);
        }
    }
    print "List of images in file system: ";
    print_array (@fs_images);

    # We now compare the lists of images
    foreach my $image_name (@sis_images) {
	if (!is_element_in_array($image_name, @oda_images)) {
            print "!!WARNING!! $image_name is in the SIS database but not ".
	          "in the ODA database\n";
	}
	if (!is_element_in_array($image_name, @fs_images)) {
            print "!!WARNING!! $image_name is in the SIS database but not ".
	          "in the file system ($sis_image_dir)\n";
	}
    }

    foreach my $image_name (@oda_images) {
        if (!is_element_in_array($image_name, @sis_images)) {
            print "!!WARNING!! $image_name is in the ODA database but not ".
                  "in the SIS database\n";
        }
        if (!is_element_in_array($image_name, @fs_images)) {
            print "!!WARNING!! $image_name is in the ODA database but not ".
                  "in the file system ($sis_image_dir)\n";
        }
    }

    foreach my $image_name (@fs_images) {
        if (!is_element_in_array($image_name, @sis_images)) {
            print "!!WARNING!! $image_name is in the file system but not ".
                  "in the SIS database\n";
        }
        if (!is_element_in_array($image_name, @oda_images)) {
            print "!!WARNING!! $image_name is in the file system but not ".
                  "in ODA\n";
        }
    }

    return 1;
}

1;
