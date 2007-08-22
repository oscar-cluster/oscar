package OSCAR::Utils;

#
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
#
#   $Id: PackageSet.pm 4833 2006-05-24 08:22:59Z bli $
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
# This module provides a set of usefull functions. Only there to avoid code
# duplication.

use strict;
use vars qw(@EXPORT @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);
use OSCAR::OCA::OS_Detect;
use Carp;

@EXPORT = qw(
            is_element_in_array
            print_array
            print_hash
            );

###############################################################################
# function to do a debug print of a hash
# inputs: leading_spaces  string to put in front of lines
#         name            string to print as the hash name
#         hash_ref        pointer to the hash to print
###############################################################################
sub print_hash {
    my( $leading_spaces, $name, $hashref ) = @_;
    print "DB_DEBUG>$0:\n====> $leading_spaces$name ->\n";
    foreach my $key ( sort keys %$hashref ) {
    my $value = $$hashref{$key};
    if (ref($value) eq "HASH") {
        print_hash(  "$leading_spaces    ", $key, $value );
    } elsif (ref($value) eq "ARRAY") {
        my $string = join(',', @$value);
        print "DB_DEBUG>$0:\n====> $leading_spaces    $key => ($string)\n";
    } elsif (ref($value) eq "SCALAR") {
        print "DB_DEBUG>$0:\n====> $leading_spaces    $key is a scalar ref\n";
        print "DB_DEBUG>$0:\n====> $leading_spaces    $key => $$value\n";
    } else {
        $value = "undef" unless defined $value;
        print "DB_DEBUG>$0:\n====> $leading_spaces    $key => <$value>\n";
    }
    }
}

###############################################################################
# Check if an element is in an array
# Parameter: 1: the element to look for
#            2: an array
# return:    1 if the element is in the array,
#            0 else.
###############################################################################
sub is_element_in_array {
    my ($element, @array) = @_;
    die ("ERROR: undefined element") if !defined ($element);

    foreach my $i (@array) {
        if (defined ($i) && ($i eq $element)) {
            return 1;
        }
    }
    return 0;
}

###############################################################################
# Print the content of an array
# Parameter: array to display.
# Return:    none.
###############################################################################
sub print_array {
    my @my_array = @_;

    print "[ ";
    foreach my $i (@my_array) {
        print $i." ";
    }
    print "]\n";
    print "Array: ".scalar(@my_array)." element(s)\n";
}
