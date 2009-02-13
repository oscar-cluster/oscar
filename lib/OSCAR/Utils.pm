package OSCAR::Utils;

#
# Copyright (c) 2007-2009 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
#
#   $Id$
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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw(@EXPORT @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);
use Config;
use OSCAR::OCA::OS_Detect;
use OSCAR::Logger;
use File::Basename;
use POSIX;
use Carp;

@EXPORT = qw(
            compactSpaces
            get_oscar_version
            get_local_arch
            get_path_perl_modules
            is_a_comment
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
    my $element = shift;
    my @array = @_;
    carp ("ERROR: undefined element") if !defined ($element);

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
    $path .= "/VERSION";
    if (! -f $path) {
    	carp "ERROR: the file $path does not exist";
	return undef;
    }
    my $cmd = "less $path | grep want_svn=0";
    my $result = `$cmd`;

    if ($result eq "") {
        $version = "unstable";
    } else {
        my $major = `less $path | grep major=`;
        my $minor = `less $path | grep minor=`;
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

    return 0 if (!defined ($str));
    return 0 if (ref($str) eq "HASH");
    return 0 if (ref($str) eq "ARRAY");
    return 0 if ($str eq "");
    
    return 1;
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
sub print_hash ($$$); # Prototype to avoid warnings when recursive calls of
                      # print_hash are made.
sub print_hash ($$$) {
    my ($leading_spaces, $name, $hashref) = @_;
    print "DEBUG>$0:\n====>print_hash\n-- $leading_spaces$name ->\n";
    foreach my $key (sort keys %$hashref) {
        my $value = $$hashref{$key};
        if (ref($value) eq "HASH") {
            print_hash( "$leading_spaces    ", $key, $value );
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

sub get_path_perl_modules () {
    my @data = Config::config_re("vendorlib");
    if (scalar (@data) > 1 || scalar (@data) == 0) {
        carp "ERROR: Impossible to know where are the Perl modules";
        return -1;
    }
    my ($key, $path) = split ("=", $data[0]);
    $path =~ m/\'(.*)\'/;
    $path = $1;
    return $path;
}

#########################################################################
#  Subroutine: compactSpaces                                            #
#  Parameters: (1) The string from which to remove spaces               #
#              (2) If $compact==1, then compress multi spaces to 1      #
#              (3) If $commas==1, then change commas to spaces          #
#  Returns   : The new string with spaces removed/compressed.           #
#  This subroutine strips off the leading and trailing spaces from a    #
#  string.  You can also pass a second parameter flag (=1) to compact   #
#  multiple intervening spaces down to one space.  You can also pass a  #
#  third parameter flag (=1) to change commas to spaces prior to doing  #
#  the space removal/compression.                                       #
#########################################################################
sub compactSpaces ($$$) {
    my($string, $compact, $commas) = @_;

    $string =~ s/,/ /g if ($commas);    # Change commas to spaces
    $string =~ s/^ *//;                 # Strip off leading spaces
    $string =~ s/ *$//;                 # Strip off trailing spaces
    $string =~ s/ +/ /g if ($compact);  # Compact multiple spaces

    return $string;  # Return string to calling procedure;
}

sub is_a_comment ($) {
    my $string = shift;

    if (trim($string) =~ /^#/) {
        return 1;
    } else {
        return 0;
    }
}

1;

__END__

=head1 Exported Functions

=over 4

=item compactSpaces

=item get_oscar_version

=item get_local_arch

=item get_path_perl_modules

=item is_a_comment ($my_string)

=item is_a_valid_string

=item is_element_in_array ($elt, @my_array)

returns 1 if $elt is in the @my_array array, 0 else.

=item merge_arrays

=item print_array

=item print_hash

=item trim

=item ltrim

=item rtrim

=back

=head1 AUTHORS

=over 4

=item Geoffroy Vallee <valleegr at ornl dot gov>

=back

=cut
