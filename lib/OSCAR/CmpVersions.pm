package OSCAR::CmpVersions;
#
# Copyright (c) 2006, Erich Focht <efocht@hpce.nec.com>
#                     All rights reserved.
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
# Generic routines for comparing version strings. Used in multiple places
# inside OSCAR.
#
# Comparison routines taken from David Lombard's update-rpms package.
# (C)opyright by David Lombard, distributed under GPL 2.
#
# $Id$

use strict;
use vars qw($verbose @EXPORT);
use POSIX;
use base qw(Exporter);
use OSCAR::Env;

@EXPORT = qw(cmp_version_strings cmp_version_strings_num);

#
# Compare two version strings.
#
sub cmp_version_strings($$) {
    my ($a, $b) = @_;

    return 0 unless defined $a && defined $b && $a ne "" && $b ne "";
    #
    #       Split a & b into runs of numeric and non-numeric strings.
    #         2.4.0 => "2.4.0"
    #         2.0p15 => "2.0", "p", "15"
    #
    #       EF:
    #         22.EL  vs. 22.0.1.EF fails
    #
    my @a;
    # ($a =~ /([\d\.]+)([^\d\.]*)/gc) ## FAILS FOR SOME CIRCUMSTANCES
    push @a, $1, ($2||"") while ($a =~ /([\d\.]+)([^0-9\.]*)/gc);
    my @aa = @a;

    my @b;
    # ($b =~ /([\d\.]+)([^\d\.]*)/gc) ## FAILS FOR SOME CIRCUMSTANCES
    push @b, $1, ($2||"") while ($b =~ /([\d\.]+)([^0-9\.]*)/gc);
    my @bb = @b;
    #
    #       Compare the strings.
    #
    my $ans;
    while (@a && @b) {
        last if $ans = cmp_version_strings_num( shift( @a ), shift( @b ) );
        last if $ans = shift( @a ) cmp shift( @b );
    }
    unless( $ans ) {
        my $ta = shift( @a ) || -1;
        my $tb = shift( @b ) || -1;
        $ans = cmp_version_strings_num( $ta, $tb );
    }
    # if( $verbose > 7 ) {
    if( $OSCAR::Env::oscar_verbose > 9 ) {
        my $word = $ans < 0 ? "<" : $ans ? ">" : "==";
        print join( " ", @aa ), " $word ", join( " ", @bb ), "\n";
    }
    return $ans;
}

#
# Compare two version numbers.
#
sub cmp_version_strings_num($$) {
    my ($a, $b) = @_;

    # EF: version problems when trailing dot in version number
    # like "2.0.1." compared to "2.0."
    # If both strings end with a dot, strip it off
    if (($a =~ /\d\.$/) && ($b =~ /\d\.$/)) {
        $a =~ s/\.$//;
        $b =~ s/\.$//;
    }
    #
    #       Split a & b into runs of numbers.
    #         21.42.08 => "21", "42", "08"
    #         2 => "2"
    #
    my @a;
    push @a, $1, ($2||"") while ($a =~ /(\d+)(\.*)/gc);

    my @b;
    push @b, $1, ($2||"") while ($b =~ /(\d+)(\.*)/gc);
    #
    #       Compare the runs.
    #
    my $ans;
    while (@a && @b) {
        last if $ans = shift( @a ) <=> shift( @b );
        last if $ans = shift( @a ) cmp shift( @b );
    }
    unless( $ans ) {
        my $ta = shift( @a ) || -1;
        my $tb = shift( @b ) || -1;
        $ans = $ta <=> $tb;
    }
    return $ans;
}
