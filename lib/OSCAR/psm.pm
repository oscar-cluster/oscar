package OSCAR::psm;

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
#use lib ".", "$ENV{OSCAR_HOME}/lib";
our @EXPORT = qw(
                select_set
                select_opkg
                unselect_opkg
                clear_list
                export_list
                show_list
                describe_package_selection
                package_hash
                );

use XML::Simple;	# Read the XML package set files
use Data::Dumper;
use OSCAR::VersionParser;
use OSCAR::opd2;

our $xml = new XML::Simple;  # XML parser object
our %list = clear_list(); # The hash that holds all the information about the OPKGs

#########################################################################
# Subroutine : select_set                                               #
# Reads a file for the OPKG set (the file should have the same name as  #
# the OPKG set) and selects all the packages in the set.  If any        #
# packages could not be selected, none are selected.                    #
# Parameters : Filename where the package set description is relative to#
#              trunk/share/package_sets (i.e. Default/debian-4-i386.xml)#
# Returns    : A string saying either OK or giving a list of packages   #
#              that could not be sucessfully selected.                  #
#########################################################################
sub select_set {
	my $filename = shift;
	my $package_set_dir = "$ENV{OSCAR_HOME}/share/package_sets/";
    my $schema_dir = "$ENV{OSCAR_HOME}/share/schemas";

	# Make sure the file is there
	
	unless (-f "$package_set_dir/$filename") {
		return "File $package_set_dir/$filename not found";
	}

	if(system("xmlstarlet --version >/dev/null 2>&1") == 0) {
		my $rc = system("xmlstarlet val -s $schema_dir/pkgset.xsd $package_set_dir/$filename >/dev/null");
		if($rc != 0) {
			return "XML does not validate against schema\n";
		}
	} else {
		print "XML not validated: xmlstarlet not installed.\n";
	}
	
	return parse_xml(read_file("$package_set_dir/$filename"));
}

#########################################################################
# Subroutine : select_opkg                                              #
# Adds an opkg to the list of selected packages.                        #
# Parameters : Name of the opkg                                         #
# Returns    : A string saying either OK or an error message.           #
#########################################################################
sub select_opkg {
	our %list;
	my $opkg = shift;
	
	# If the opkg is already selected, ignore it
	if (exists($list{package}{$opkg})) {
		return 'OK - Already selected';
	# Otherwise add it into the list without any restrictions
	} else {
		$list{package}{$opkg} = {};
		return 'OK';
	}
}

#########################################################################
# Subroutine : unselect_opkg                                            #
# Removes an opkg from the list of selected packages.                   #
# Parameters : Name of the opkg                                         #
# Returns    : A string saying either OK or an error message.           #
#########################################################################
sub unselect_opkg {
	our %list;
	my $opkg = shift;
	
	# Make sure the opkg is selected already
	if (!exists($list{package}{$opkg})) {
		return 'OK - Not selected';
	# If it is, remove it
	} else {
		delete $list{package}{$opkg};
		return 'OK';
	}
}

#########################################################################
# Subroutine : clear_list                                               #
# Removes all packages from the list of packages to install.            #
# Parameters : None                                                     #
# Returns    : None                                                     #
#########################################################################
sub clear_list {
	our %list;
	
	%list = (distro => {version => '', name => ''} ,
		arch => '',
		package => {}
	);
}

#########################################################################
# Subroutine : export_list                                              #
# Exports a stub of the selected packages to the specified file.  The   #
# use may need to fill in some information that is not already stored   #
# (arch, dist, name).  This file is in a format that can be read back   #
# into the PSM at a later time.                                         #
# Parameters : Name of the flie                                         #
# Returns    : None                                                     #
#########################################################################
sub export_list {
	our %list;
	my $filename = shift;
	my $name = shift;
	my $version = shift;
	my $distro = shift;
	my $distver = shift;
	my $arch = shift;
	
	open (OUTFILE, ">$filename") || die "Cannot open file $filename: $!\n";
	
	print OUTFILE "<?xml version=\"1.0\" encoding=\"ISO-8859-\"?>\n\n<packageSet>\n";
	print OUTFILE "\t<name> $name </name>\n" if $name;
	print OUTFILE "\t<version> $version </version>\n" if $version;
	
	# If the user supplied a distro and version use that one
	if ($distro && $distver) {
		print OUTFILE "\t<distro>\n";
		print OUTFILE "\t\t<name> $distro </name>\n";
		print OUTFILE "\t\t<version> $distver </version>\n";
		print OUTFILE "\t</distro>\n";
	# If the user didn't supply one and the hash already had one use that one
	} elsif (exists($list{distro}{name}) && exists($list{distro}{version})) {
		print OUTFILE "\t<distro>\n";
		print OUTFILE "\t\t<name> $list{distro}{name} </name>\n";
		print OUTFILE "\t\t<version> $list{distro}{version} </version>\n";
		print OUTFILE "\t</distro>\n";
	}
	
	# If the user supplied an arch use that one
	if ($arch) {
		print OUTFILE "\t<arch> $arch </arch>\n\n";
	# If the user didn't supply one and the hash already has one use that one
	} elsif (exists($list{arch})) {
		print OUTFILE "\t<arch> $list{arch} </arch>\n\n";
	}
	
	# Start printing the hashes
	foreach my $package (show_list()) {
		my %info = describe_package_selection($package);
		print OUTFILE "\t<package name=\"$package\">\n";
		
		# Make sure there was information
		if (exists($info{compare}) && $info{number}) {
			print OUTFILE "\t\t<version>\n";
			print OUTFILE "\t\t\t<compare> $info{compare} </compare>\n";
			print OUTFILE "\t\t\t<number> $info{number} </number>\n";
			print OUTFILE "\t\t</version>\n";
		}
		
		print OUTFILE "\t</package>\n\n";
	}
	
	# Wrap it up
	print OUTFILE "</packageSet>\n";
	
	close OUTFILE;
}

#########################################################################
# Subroutine : show_list                                                #
# Gets the list of packages to be installed.                            #
# Parameters : None                                                     #
# Returns    : An array containing the names of all the packages to be  #
#              installed.                                               #
#########################################################################
sub show_list {
	our %list;
	
	return keys(%{$list{package}});
}

#########################################################################
# Subroutine : describe_package_selection                               #
# Gets the description of the restrictions placed on the package.       #
# Parameters : Name of the opkg                                         #
# Returns    : A hash containing the description information.           #
#########################################################################
sub describe_package_selection {
	our %list;
	my $opkg = shift;
	
	return %{$list{package}{$opkg}};
}

#########################################################################
# Subroutine : package_hash                                             #
# Outputs the hash to be used by another tool that will install the     #
# packages.                                                             #
# Parameters : None                                                     #
# Returns    : The information as a hash.                               #
#########################################################################
sub package_hash {
	our %list;
	
	return %list;
}

#########################################################################
# Subroutine : read_file                                                #
# Reads a file and returns a hash containing the information in the XML #
# Parameters : Filename where the package set description is            #
# Returns    : A hash continaing the information in the XML file        #
#########################################################################
sub read_file {
	my $filename = shift;

 	my %data = %{$xml->XMLin($filename, ForceArray => ['package'])};

	return \%data;
}

#########################################################################
# Subroutine : parse_xml                                                #
# This subroutine is long, but it should be well structured and easy to #
#   modify later                                                        #
# Takes the information from the XML file in the form of a hash and     #
# combines it with the information already stored in the list of        #
#   packages to be installed                                            #
# Does some error checking to make sure the sets are compatable (same   #
#   distro, same arch)                                                  #
# If the add failed, it will try to remove anything added into the hash #
# Parameters : The hash containing the new XML information              #
# Returns    : A string containing either 'OK' or an error message      #
#########################################################################
sub parse_xml {
	our %list;
	my $xmlinfo = shift;

	# Check the distro
	if($list{distro}{name} eq '') { # If this is the first file, add the info
		$list{distro}{version} = rw($$xmlinfo{distro}{version});
		$list{distro}{name} = rw($$xmlinfo{distro}{name});
	} else { # If this is not the first file, check to see if it matches
		if($list{distro}{version} ne rw($$xmlinfo{distro}{version}) ||
			$list{distro}{name} ne rw($$xmlinfo{distro}{name})) {
			return 'Different distro information';
		}
	}
	
	# Check the architecture
	if($list{arch} eq '') { # If this is the first file, add the info
		$list{arch} = rw($$xmlinfo{arch});
	} else { # If this is not the first file, check to see if it matches
		if($list{arch} ne rw($$xmlinfo{arch})) {
			return 'Different arch information';
		}
	}

	# Go through the list of packages and find the ones that cause problems
	# If there is going to be an issue go ahead and fail now instead of 
	# partially adding the packages and then not being able to remove them
	# This also saves trouble later by preventing error checking when adding
	my @packages = keys(%{$$xmlinfo{package}});
	my @problempackages;
	my @goodpackages;
	foreach my $name (@packages) {
	
		# If the package is already in the list and 
		# the xml has a version requirement
		if(exists($list{package}{$name}) && 
			exists($$xmlinfo{package}{$name}{version}) &&
			exists($list{package}{$name}{number})) {
		
			# Set up these variables to save a lot of headaches later
			my $list_comp = $list{package}{$name}{compare};
			my $list_number = $list{package}{$name}{number};
			my $xmlinfo_comp = rw($$xmlinfo{package}{$name}{version}{compare});
			my $xmlinfo_number = rw($$xmlinfo{package}{$name}{version}{number});
			my $comparison = version_compare(parse_version($xmlinfo_number), parse_version($list_number));
			
			# Check to see if the version comparisons are compatible
			
			# If list is gt or gte
			if ($list_comp eq 'gt' || $list_comp eq 'gte') {
				# AND xml is gt or gte
				if ($xmlinfo_comp eq 'gt' || $xmlinfo_comp eq 'gte') {
					# AND xmlnum is gt
					if ($comparison > 0) {
						# Take action later
						push(@goodpackages, $name);
						next;
					# AND xmlnum is lt
					} elsif ($comparison < 0) {
						# Ignore
						next;
					# AND xmlnum is eq AND list is gt
					} elsif ($comparison == 0 && $list_comp eq 'gt') {
						push (@problempackages, $name);
						next;
					}
				# AND xml is eq
				} elsif ($xmlinfo_comp eq 'eq') {
					# AND xmlnum is gt
					if ($comparison > 0) {
						# Take action later
						push(@goodpackages, $name);
						next;
					
					# AND list is gte AND xmlnum is eq
					} elsif ($comparison == 0 && $list_comp eq 'gte') {
						# Take action later
						push(@goodpackages, $name);
						next;
					}
				}
			# If list is lt or lte
			} elsif ($list_comp eq 'lt' || $list_comp eq 'lte') {
				# AND xml is lt or lte
				if ($xmlinfo_comp eq 'lt' || $xmlinfo_comp eq 'lte') {
					# AND xmlnum is lt
					if ($comparison < 0) {
						# Take action later
						push(@goodpackages, $name);
						next;
					# AND xmlnum is gt
					} elsif ($comparison > 0) {
						# Ignore
						next;
					# AND xmlnum is eq AND list is lt
					} elsif ($comparison == 0 && $list_comp eq 'lt') {
						# Error
						push(@problempackages, $name);
						next;
					}
				# AND xml is eq
				} elsif ($xmlinfo_comp eq 'eq') {
					# AND xmlnum is lt
					if ($comparison < 0) {
						# Take action later
						push(@goodpackages, $name);
						next;
					# AND list is lte AND xmlnum is eq
					} elsif ($comparison == 0 && $list_comp eq 'lte') {
						# Take action later
						push(@goodpackages, $name);
						next;
					}
				}
			# If list is eq (none of these will require action later)
			} elsif ($list_comp eq 'eq') {
				# AND xml is gt AND xmlnum is lt
				if ($xmlinfo_comp eq 'gt' && $comparison < 0) {
					# Ignore
					next;
				# AND xml is gte AND xmlnum is lte
				} elsif ($xmlinfo_comp eq 'gte' && $comparison <= 0) {
					# Ignore
					next;
				# AND xml is lt AND xmlnum is gt
				} elsif ($xmlinfo_comp eq 'lt' && $comparison > 0) {
					# Ignore
					next;
				# AND xml is lte AND xmlnum is gte
				} elsif ($xmlinfo_comp eq 'lte' && $comparison >= 0) {
					# Ignore
					next;
				# AND xml is eq AND xmlnum is eq
				} elsif ($xmlinfo_comp eq 'eq' && $comparison == 0) {
					# Ignore
					next;
				}
			}
		# If it is not in the list or doesn't have a version requirement
		# deal with it later
		} else {
			push(@goodpackages, $name);
			next;
		}
		
		# If we made it here and haven't started over yet, there is an error
		push(@problempackages, $name);
	}
	
	# If there is something in the problempackages list, yell and quit
	my $size = scalar @problempackages;
	if($size > 0) {
		my $outstring = "These packages are not compatable:";
		foreach my $temp (@problempackages) {
			$outstring = $outstring . " " . $temp;
		}
		return $outstring;
	}
	
	# Actually add the packages to the list
	foreach my $name (@goodpackages) {
		# Check to see if the XMl has a repository
		if (exists($$xmlinfo{package}{$name}{repository})) {
			# Call the OPD2 code
			OSCAR::opd2::scan_repository($$xmlinfo{package}{$name}{repository});
		}
		
		my ($xmlinfo_comp, $xmlinfo_number, $list_comp, $list_number);
	
		if (exists($$xmlinfo{package}{$name}{version})) {
			# Set up these variables to save a lot of headaches later
			$xmlinfo_comp = rw($$xmlinfo{package}{$name}{version}{compare});
			$xmlinfo_number = rw($$xmlinfo{package}{$name}{version}{number});
		}
		
		if (exists($list{package}{$name}) && exists($list{package}{$name}{compare})) {
			# Set up these variables to save a lot of headaches later
			$list_comp = $list{package}{$name}{compare};
			$list_number = $list{package}{$name}{number};
		} 
		
		# If the package is new, and has requirements, copy them
		if(!exists($list{package}{$name}) && exists($$xmlinfo{package}{$name}{version})) {
			$list{package}{$name}{compare} = $xmlinfo_comp;
			$list{package}{$name}{number} = $xmlinfo_number;
			next;
			
		# If the package is new, and has no requirements, add it easily
		} elsif(!exists($list{package}{$name}) && !exists($$xmlinfo{package}{$name}{version})) {
			$list{package}{$name} = {};
			
		# If the package is not new, and has no requirements, ignore it
		} elsif(exists($list{package}{$name}) && !exists($$xmlinfo{package}{$name}{version})) {
			next;
			
		# If the package is not new, and the old one has no requirements
		# add the new ones
		} elsif(exists($list{package}{$name}) && 
			exists($$xmlinfo{package}{$name}{version}) && 
			!exists($list{package}{$name}{number})) {
			$list{package}{$name}{compare} = $xmlinfo_comp;
			$list{package}{$name}{number} = $xmlinfo_number;
			
		# If the package is new and has new requirements, do the fun part
		# Note - This section DOES NOT do error checking, that is done above
		} else {
			
			# Do a comparison now to save space later
			my $comparison = version_compare(parse_version($xmlinfo_number), parse_version($list_number));
			
			# If list is gt or gte
			if ($list_comp eq 'gt' || $list_comp eq 'gte') {
				# AND xml is gt or gte AND xmlnum is gte
				if (($xmlinfo_comp eq 'gt' || $xmlinfo_comp eq 'gte') && $comparison >= 0) {
					# Replace listnum and listcmp
					$list{package}{$name}{compare} = $xmlinfo_comp;
					$list{package}{$name}{number} = $xmlinfo_number;
				# AND xml is eq AND xmlnum is gt
				} elsif ($xmlinfo_comp eq 'eq' && $comparison > 0) {
					# Replace listnum and listcmp
					$list{package}{$name}{compare} = $xmlinfo_comp;
					$list{package}{$name}{number} = $xmlinfo_number;
				# AND xmlnum is eq and list is gte
				} elsif ($comparison == 0 && $list_comp eq 'gte') {
					# Replace listcmp with eq
					$list{package}{$name}{compare} = 'eq';
				}
			# If list is lt or lte
			} elsif ($list_comp eq 'lt' || $list_comp eq 'lte') {
				# AND xml is lt or lte AND xmlnum is lte
				if (($xmlinfo_comp eq 'lt' || $xmlinfo_comp eq 'lte') && $comparison <= 0) {
					# Replace listnum and listcmp
					$list{package}{$name}{compare} = $xmlinfo_comp;
					$list{package}{$name}{number} = $xmlinfo_number;
				# AND xml is eq AND xmlnum is lt
				} elsif ($xmlinfo_comp eq 'eq' && $comparison < 0) {
					# Replace listnum and listcmp
					$list{package}{$name}{compare} = $xmlinfo_comp;
					$list{package}{$name}{number} = $xmlinfo_number;
				# AND xmlnum is eq and list is lte
				} elsif ($comparison == 0 && $list_comp eq 'lte') {
					# Replace listcmp with eq
					$list{package}{$name}{compare} = 'eq';
				}
			}
		}
	}
	
	# We're done doing everything and haven't failed, so say OK and quit
	return 'OK';
}

sub rw {
	my $variable = shift;
	
	$variable =~ s/^\s+//;
	$variable =~ s/\s+$//;
	
	return $variable;
}


1;
