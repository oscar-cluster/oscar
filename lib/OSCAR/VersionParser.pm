package OSCAR::VersionParser;

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
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
#   Copyright (c) 2007 Oak Ridge National Laboratory
#                      All rights reserved
#
#   Code translated from the dpkg version parsing and comparison tool
#
#   This module tests two OPKG version numbers according to a comparison

use strict;

use vars qw(@EXPORT);
use base qw(Exporter);
our @EXPORT = qw( version_satisfied parse_version version_compare );

our $debug;
	
#################################################################
# Parses a string into the version and release parts            #
# Parameters:                                                   #
# version_string - A string representation of the version       #
#                                                               #
# Returns:                                                      #
#   An array where the first position is the version and the    #
#   second is the revision                                      #
#################################################################
sub parse_version {
	my $version_string = shift;
	
	if ($version_string eq '') {return "Version string is empty"};
	
	# The position in the version string
	my $verpos = 0;
	
	# The next character to be parsed
	my $ver_char = substr($version_string, $verpos, 1);
	
	# Trim leading and trailing space
	while($verpos < length($version_string) && ($ver_char eq ' ' || $ver_char eq "\t" || $ver_char eq "\n") ) {
		print $ver_char . "\n";
		$ver_char = substr($version_string, ++$verpos, 1);
	}
	
	# Save the position of the first "real character"
	my $firstpos = $verpos;
	
	while($verpos < length($version_string) && $ver_char ne ' ' && $ver_char ne "\t" && $ver_char ne "\n") {
		$ver_char = substr($version_string, ++$verpos, 1);
	}
	
	# Save the position of the last "real character"
	my $endpos = $verpos;
	
	# Check for extra chars after trailing spaces
	while ($verpos < length($version_string) && ( $ver_char eq ' ' || $ver_char eq "\t" || $ver_char eq "\n") ) {
		$ver_char = substr($version_string, ++$verpos, 1);
	}
	
	if($ver_char) {return "Version string has embedded spaces";}
	
	my $version = "";
	my $revision = "";
	
	$verpos = $firstpos;
	$ver_char = substr($version_string, $verpos, 1);
	
	# Search for the first hyphen
	while ($verpos < length($version_string) && ($ver_char ne '-' && $ver_char ne ' ' && $ver_char ne "\t" && $ver_char ne "\n") ) {
		$version = $version . $ver_char;
		$ver_char = substr($version_string, ++$verpos, 1);
	}
	
	# Move the verpos variable
	$verpos++;
	
	# Everything after the hyphen goes under revision
	if($verpos < $endpos) {
		$revision = substr($version_string, $verpos, $endpos - $verpos);
	}
	
	return $version, $revision;
}

#################################################################
# Tests two versions to see if it meets a specified comparison  #
# Parameters:                                                   #
# first_version  - The version part (major, minor, subversion)  #
#                  of the entire version number for the first   #
# first_release  - The release part of the first                #
# second_version - The version part (major, minor, subversion)  #
#                  of the entire version number for the second  #
# second_release - The release part of the second               #
# comparison     - The test to use for the comparison           #
#                  Valid inputs - gt, lt, gte, lte, eq          #
# debug          - If there is something other than 0 here it   #
#                     will print debugging information          #
#                                                               #
# Returns:                                                      #
#   Less than 0     - If there is an error                      #
#   0               - If the comparison is false                #
#   Greater than 0  - If the comparison is true                 #
#################################################################
sub version_satisfied {
	my $first_version = shift;
	my $first_release = shift;
	my $second_version = shift;
	my $second_release = shift;
	my $comparison = shift;
	our $debug = shift;
	
	my $r;
	
	if($comparison ne 'gt' && $comparison ne 'lt' && $comparison ne 'gte' && 
		$comparison ne 'lte' && $comparison ne 'eq') {
		return -1;
	}
	
	$r = version_compare($first_version, $first_release, $second_version,
		$second_release);
		
	print "R: $r\n" if $debug;
	
	if ($comparison eq 'gt') {
		return 1 if ($r > 0);
	} elsif ($comparison eq 'lt') {
		return 1 if ($r < 0);
	} elsif ($comparison eq 'gte') {
		return 1 if ($r >= 0);
	} elsif ($comparison eq 'lte') {
		return 1 if ($r <= 0);
	} elsif ($comparison eq 'eq') {
		return 1 if ($r == 0);
	}
	
	return 0;
}

# Compares two versions according to the scheme specified in the wiki 
# (http://svn.oscar.openclustergroup.org/trac/oscar/wiki/OPKGVersioning)
sub version_compare {
	my $first_version = shift;
	my $first_release = shift;
	my $second_version = shift;
	my $second_release = shift;
	
	my $r;
	
	$r = verrevcmp($first_version, $second_version);
	if ($r) {return $r;}
	
	else {
		return verrevcmp($first_release, $second_release);
	}
}

# Returns the ordering number of a character
# Digits are given an order of 0 (when it's time to compare digits, they don't
# 	need this subroutine)
# Non-digits are ordered by their ASCII value
sub order {
	my $x = shift;
	
	if ($x eq '~') {return -1;}
	elsif ($x =~ /\d/) {return 0;}
	elsif ($x !~ /\d/) {
		return ord($x);
	} else {
		return ord($x + 256);
	}
}

# Does the actual comparison between two parts of the entire version
# This only compares version to version or release to release, not a combination
sub verrevcmp {
	our $debug;

	print "verrevcmp\n" if $debug;
	my $val = shift;
	my $ref = shift;
	
	print "VAL: $val\n" if $debug;
	print "REF: $ref\n" if $debug;
	
	# The position in the version variables
	my $valpos = 0;
	my $refpos = 0;
	
	if (!$val) {$val = "";}
	if (!$ref) {$ref = "";}
	
	while ( $valpos < length($val) || $refpos < length($ref) ) {
		print "OUTER LOOP\n" if $debug;
	
		# Keeps track of the first difference in so that if we need to go back
		# to it we can.  Useful for cases such as v2 vs. v10.  The second should
		# evaluate as greater, but there is no way to know it when we are at the
		# first character
		my $first_diff = 0;
		
		# The next character to be evaluated
		my $val_char = substr($val, $valpos, 1);
		my $ref_char = substr($ref, $refpos, 1);
		
		print "VAL_CHAR: $val_char\n" if $debug;
		print "REF_CHAR: $ref_char\n" if $debug;
		
		# While there is something in $val and the next character in val is not
		# a digit, or there is something in $ref and the next character in ref
		# is not a digit
		while ( ($val && $val_char !~ /\d/) || ($ref && $ref_char !~ /\d/) ) {
			print "INNER LOOP\n" if $debug;
			my $vc = order(substr($val, $valpos, 1));
			my $rc = order(substr($ref, $refpos, 1));
			
			print "VC: $vc\n" if $debug;
			print "RC: $rc\n" if $debug;
			
			# If one has a nondigit and the other doesn't or the other's
			# nondigit is smaller, return that the larger won
			if($vc != $rc) {
				return $vc - $rc;
			}
			
			# Increment the counters
			$valpos++;
			$refpos++;
			
			# Move the position of the next character
			$val_char = substr($val, $valpos, 1);
			$ref_char = substr($ref, $refpos, 1);
			
			print "VAL_CHAR: $val_char\n" if $debug;
			print "REF_CHAR: $ref_char\n" if $debug;
		}
		
		#$valpos = 0;
		#$refpos = 0;
		
		$val_char = substr($val, $valpos, 1);
		$ref_char = substr($ref, $refpos, 1);
		
		print "VAL_CHAR: $val_char\n" if $debug;
		print "REF_CHAR: $ref_char\n" if $debug;
		
		# While the next character in val is a digit and the next character in 
		# ref is a digit
		while( $val_char =~ /\d/ && $ref_char =~ /\d/) {
			print "INNER LOOP 2\n" if $debug;
			
			# If one has a bigger digit, remember it so we can come back to it
			# later
			if ($first_diff == 0) { $first_diff = $val_char - $ref_char; }
			
			print "FIRST_DIFF: $first_diff\n" if $debug;
			
			$valpos++;
			$refpos++;
			
			$val_char = substr($val, $valpos, 1);
			$ref_char = substr($ref, $refpos, 1);
			
			print "VAL_CHAR: $val_char\n" if $debug;
			print "REF_CHAR: $ref_char\n" if $debug;
		}
		
		# If one has more digits that haven't been evaluated, it wins
		if ($val_char =~ /\d/) {return 1;}
		elsif ($ref_char =~ /\d/) {return -1;}
		
		# If they have the same number of digits, the one with the bigger
		# digits wins
		if($first_diff != 0) {return $first_diff};
		
	}
	
	# It's a tie, give up
	return 0;
}

1;
