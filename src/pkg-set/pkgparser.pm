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
#   $Id$

use strict;

use vars qw(@EXPORT);
use base qw(Exporter);
our @EXPORT = qw(read_file get_package_sets get_packages);

use XML::Simple;	# Read the XML package set files
use Data::Dumper;

our $xml = new XML::Simple;  # XML parser object
our $filename;

our $data;

#########################################################################
# Subroutine : read_file                                                #
# Opens the file and reads in the package list and version information  #
# Parameters : Filename where the package set description is            #
# Returns    : None                                                     #
#########################################################################
sub read_file {
	our $data;
	$filename = shift;

	$data = $xml->XMLin($filename, ForceArray => 1);
}

#########################################################################
# Subroutine : get_package_sets                                         #
# Gets the names of all the package sets stored in the package sets file#
# Parameters : None                                                     #
# Returns    : An array of the package set names                        #
#########################################################################
sub get_package_sets {
	our $data;

	my @sets = keys(%{$data->{packageSet}});

	return @sets;
}

#########################################################################
# Subroutine : get_packages                                             #
# Gets the names of all the packages in the package set                 #
# Parameters : Name of the package set                                  #
# Returns    : An hash of the package information                       #
#########################################################################
sub get_packages {
	our $data;
	my $packageSet = shift;

	my @packages = keys(%{$data->{packageSet}->{$packageSet}->{package}});

	return @packages;
}

1;
