#!/usr/bin/perl

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
#	This module is for converting the hash that comes out of OSM into database
#	form for OPM.
#
#	TODO - Use version restrictions stored in the hash
#		There are also other pieces of info not used (distro, arch, lists
#		of packages and sets selected). These can be saved or discarded.
#        - This should be a library. 
#
#   $Id$

use strict;

use lib "/usr/lib/perl5/OSCAR", "$ENV{OSCAR_HOME}/lib";
use OSCAR::Database;
	
use Data::Dumper;

use vars qw(@EXPORT);
use base qw(Exporter);
our @EXPORT = qw(
	convert_hash_to_oda
	);
	
sub convert_hash_to_oda {
	my %data = %{$_[0]};
	
	# Go through each node in the hash
	for my $nodename (keys(%data)) {
		
		# Go through each package for the node
		for my $package (keys( $data{$nodename}{package} )) {
			
			# Set the package's requested values to 'finished'
			my %options;
			my @errors;
			my %field_values;
			$field_values{requested} = 'finished';
			update_node_package_status_hash(\%options, $nodename, $package, 
					\%field_values, \@errors);
		}
	}
}
