package OSCAR::Utils;

#
# Copyright (c) 2007 Geoffroy Vallee <valleegr@ornl.gov>
#                    Oak Ridge National Laboratory
#                    All rights reserved.
#
#   $Id: Utils.pm 4833 2006-05-24 08:22:59Z bli $
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
use OSCAR::Logger;
use File::Basename;
use POSIX;
use Carp;

@EXPORT = qw(
            download_file
            get_oscar_version
            get_local_arch
            is_a_valid_string
            is_element_in_array
            merge_arrays
            print_array
            print_hash
            trim
            ltrim
            rtrim
            );

my $verbose = $ENV{OSCAR_VERBOSE};

################################################################################
# Check if an element is in an array.                                          #
#                                                                              #
# Parameter: element, the element to look for                                  #
#            array, an array                                                   #
# return:    1 if the element is in the array,                                 #
#            0 else.                                                           #
################################################################################
sub is_element_in_array ($@) {
    my ($element, @array) = @_;
    die ("ERROR: undefined element") if !defined ($element);

    foreach my $i (@array) {
        if (defined ($i) && ($i eq $element)) {
            return 1;
        }
    }
    return 0;
}

################################################################################
# Print the content of an array.                                               #
#                                                                              #
# Parameter: array to display.                                                 #
# Return:    none.                                                             #
################################################################################
sub print_array (@) {
    my @my_array = @_;

    print "[ ";
    foreach my $i (@my_array) {
        print $i." ";
    }
    print "]\n";
    print "Array: ".scalar(@my_array)." element(s)\n";
}

################################################################################
# Return the OSCAR version, for that we parse the $OSCAR_HOME/VERSION.         #
#                                                                              #
# Input: None.                                                                 #
# Return: the OSCAR version (string), note that if this is the SVN version, it #
#         returns "unstable". Returns undef if error.                          #
################################################################################
sub get_oscar_version {
    my $version;
    my $path;
    if (defined $ENV{OSCAR_HOME} && -f "$ENV{OSCAR_HOME}/VERSION") {
        $path = "$ENV{OSCAR_HOME}";
    } elsif ( -f "/etc/oscar/VERSION" ) {
        $path = "/etc/oscar";
    } else {
        carp "ERROR: Impossible to get the OSCAR version";
        return undef;
    }
    my $cmd = "less $path/VERSION | grep want_svn=0";
    my $result = `$cmd`;

    if ($result eq "") {
        $version = "unstable";
    } else {
        my $major = `less $path/VERSION | grep major=`;
        my $minor = `less $path/VERSION | grep minor=`;
        chomp ($major);
        chomp ($minor);
        $major =~ s/^major=//;
        $minor =~ s/^minor=//;
        $version=$major.".".$minor;
    }
    return $version;
}

################################################################################
# Check if a string is valid. An unvalid string is an empty or undefined       #
# string.                                                                      #
#                                                                              #
# Input: string to abalyze.                                                    #
# Return: 1 if the string is valid, 0 else.                                    #
################################################################################
sub is_a_valid_string ($) {
    my $str = shift;

    if (!defined ($str) || $str eq "") {
        return 0;
    } else {
        return 1;
    }
}

################################################################################
# Exported function to print a dump of a hash                                  #
#                                                                              #
# Inputs:  $leading_spaces    some description(string) about the hash          #
#          $name              name(string) for the hash                        #
#          $hashref           reference of the hash to print out               #
#                                                                              #
# Outputs: prints out the hash contents                                        #
################################################################################
sub print_hash {
    my ($leading_spaces, $name, $hashref) = @_;
    print "DEBUG>$0:\n====> in oda::print_hash\n-- $leading_spaces$name ->\n";
    foreach my $key (sort keys %$hashref) {
        my $value = $$hashref{$key};
        if (ref($value) eq "HASH") {
            print_hash(  "$leading_spaces    ", $key, $value );
        } elsif (ref($value) eq "ARRAY") {
            print "-- $leading_spaces    $key => (";
            print join(',', @$value);
            print ")\n";
        } elsif (ref($value) eq "SCALAR") {
            print "-- $leading_spaces    $key is a scalar ref\n";
            print "-- $leading_spaces    $key => $$value\n";
        } else {
            $value = "undef" unless defined $value;
            print "-- $leading_spaces    $key => <$value>\n";
        }
    }
}

###############################################################################
# Download a given file, using wget.                                          #
#                                                                             #
# Input: url, url of the file to download.                                    #
#        dest, directory where the file needs to be saved (the filename is    #
#        preserved.                                                           #
# Return: the file path (including the filename), -1 if errors.               #
###############################################################################
sub download_file ($$) {
    my ($url, $dest) = @_;

    oscar_log_subsection "Downloading $url";
    if (! -d $dest) {
        carp "ERROR: Impossible to download the file ($url), the destination ".
             "is not a valid directory ($dest)";
        return undef;
    }
    my $file = basename ($url);
    if ( -f "$dest/$file" ) {
        # If the file is already there, we just successfully exist
        oscar_log_subsection "\tThe file is already downloaded." if $verbose;
        return "$dest/$file";
    }
    my $cmd = "cd $dest; wget $url";
    oscar_log_subsection "Executing: $cmd\n" if $verbose;
    if (system ($cmd)) {
        carp "ERROR: Impossible to execute $cmd";
        return undef;
    }
    return "$dest/$file";
}

################################################################################
# Detects the architecture of the local machine.                               #
#                                                                              #
# Return: the local architecture. For i*86 architecutre, we always return      #
#         i386                                                                 #
################################################################################
sub get_local_arch () {
    my $arch = (uname)[4];
    if ($arch =~ /i*86/) {
        $arch = "i386";
    }
    return $arch;
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

# Left trim function to remove leading whitespace
sub ltrim($)
{
    my $string = shift;
    $string =~ s/^\s+//;
    return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim($)
{
    my $string = shift;
    $string =~ s/\s+$//;
    return $string;
}

sub merge_arrays ($$) {
    my ($array_ref1, $array_ref2) = @_;

    if (!defined ($array_ref1) || !defined ($array_ref2)) {
        carp "ERROR: Impossible to merge the arrays";
        return undef;
    }
    my @array = @$array_ref1;
    foreach my $e (@$array_ref2) {
        unshift (@array, $e);
    }
    return @array;
}

1;
