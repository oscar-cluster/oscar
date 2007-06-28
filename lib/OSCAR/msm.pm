package OSCAR::msm;

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
use lib ".", "$ENV{OSCAR_HOME}/lib";
our @EXPORT = qw( describe_set list_sets machine_type );

use XML::Simple;	# Read the XML package set files
use Data::Dumper;

our $xml = new XML::Simple;  # XML parser object
our $filename = "$ENV{OSCAR_HOME}/share/machinesets.xml";

our %list;

# Check to see if the xml validates against the schema

if(system("xmlstarlet --version >/dev/null 2>&1") == 0) {
	my $rc = system("xmlstarlet val -s $ENV{OSCAR_HOME}/share/schemas/machineset.xsd $filename >/dev/null");
	if($rc != 0) {
		return "XML does not validate against schema\n";
	}
} else {
	print "XML not validated: xmlstarlet not installed.\n";
}

%list = %{$xml->XMLin($filename, ForceArray => ['machine', 'machineSet'])};

#########################################################################
# Subroutine : describe_set                                             #
# Lists the names of all the machines in the specified machine set      #
# Parameters : The name of a machine set                                #
# Returns    : A list of the machine names in the set                   #
#########################################################################
sub describe_set {
	our %list;
	my $set_name = shift;
	
	return @{$list{machineSet}{$set_name}{hostname}};
}

#########################################################################
# Subroutine : list_sets                                                #
# Lists the names of all the machine sets in the machine sets file      #
# Parameters : None                                                     #
# Returns    : A list of the machine set names                          #
#########################################################################
sub list_sets {
	our %list;
	
	return keys %{$list{machineSet}};
}

#########################################################################
# Subroutine : machine_type                                             #
# Gives the type of a specified machine                                 #
# Parameters : The hostname of the machine                              #
# Returns    : The type of the machine                                  #
#########################################################################
sub machine_type {
	our %list;
	my $hostname = shift;
	
	for my $h (@{$list{machine}}) {
		if($$h{hostname} eq $hostname) {
			return $$h{nodeType};
		}
	}
}
