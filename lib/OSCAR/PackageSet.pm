package OSCAR::PackageSet;
#
# Copyright (c) 2007-2008 Geoffroy Vallee <valleegr@ornl.gov>
#                         Oak Ridge National Laboratory
#                         All rights reserved.
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

BEGIN {
    if (defined $ENV{OSCAR_HOME}) {
        unshift @INC, "$ENV{OSCAR_HOME}/lib";
    }
}

use strict;
use vars qw(@EXPORT @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);
use OSCAR::OCA::OS_Detect;
use OSCAR::FileUtils;
use OSCAR::Logger;
use OSCAR::Utils;
use XML::Simple;
use Data::Dumper;
use Carp;

@EXPORT = qw(
            duplicate_package_set
            get_local_package_set_list
            get_list_opkgs_in_package_set
            get_package_sets
            get_opkgs_path_from_package_set
            );

my $verbose = $ENV{OSCAR_VERBOSE};
use vars qw ($package_set_dir);
if (defined $ENV{OSCAR_HOME}) {
    $package_set_dir = $ENV{OSCAR_HOME}."/share/package_sets";
} else {
    $package_set_dir = "/usr/share/oscar/package_sets";
}

sub duplicate_package_set ($$$) {
    my ($ps, $new_ps, $distro) = @_;

    require File::Copy;
    my $orig = "$package_set_dir/$ps/$distro.xml";
    if (! -f $orig) {
        carp "ERROR: File to copy does not exist ($orig)";
        return -1;
    }

    my $dest_dir = "$package_set_dir/$new_ps";
    my $dest = "$package_set_dir/$new_ps/$distro.xml";
    if (-f $dest) {
        OSCAR::Logger::oscar_log_subsection "File $dest already exists, doing ".
            "nothing";
        return 0;
    }

    if (! -d $dest_dir) {
        require File::Path;
        File::Path::mkpath ($dest_dir)
            or (carp "ERROR: Impossible to create the directory $dest_dir",
                return -1);
    }
    File::Copy::copy ($orig, $dest)
         or (carp "ERROR: Impossible to copy file ($orig, $dest)", return -1);

    return 0;
}

# Package sets are defined via files. The files are named based on the target
# Linux distro and those files are in a directory that has the name of the
# package set. Therefore to get the list of package sets, we need to have the
# name of the directories in the location where package sets are stored and for
# each of those directory, get the files name.
# We assume we create a namespace for each package sets based on the following
# rule:
#       "<package_set_name> - <distro_id>"
#
# Input: None.
# Return: array of package sets name.
sub get_package_sets_per_distro () {
    my @pkg_sets;
    my @dirs = OSCAR::FileUtils::get_dirs_in_path ($package_set_dir);
    foreach my $d (@dirs) {
        my @files = OSCAR::FileUtils::get_files_in_path ("$package_set_dir/$d");
        foreach my $file (@files) {
            if ($file =~ /^(.*)\.xml/) {
                push (@pkg_sets, "$d - $1");
            }
        }
    }
    return @pkg_sets;
}

# Package sets are defined via files. We get here only the list of package
# sets, we do not pay attention to the package set per distro.
#
# Input: None.
# Return: array of package sets name.
sub get_package_sets () {
    my @dirs = OSCAR::FileUtils::get_dirs_in_path ($package_set_dir);
    return @dirs;
}

###############################################################################
# Scan package sets defined in share/package_sets based on the local
# distribution id. For instance, on debian 4 i386, we will look into the file
# share/package_sets/<pkg_set>/debian-4-i386.xml.
# Parameter: none.
# Return:    list of package sets. Note that we skip Default which is used by
#            default.
###############################################################################
sub get_local_package_set_list {
    my @packageSets = ();
    die ("ERROR: The package set directory does not exist ".
        "($package_set_dir)") if ( ! -d $package_set_dir );

    opendir (DIRHANDLER, "$package_set_dir")
        or die ("ERROR: Impossible to open $package_set_dir");
    foreach my $dir (sort readdir(DIRHANDLER)) {
        # We skip few directories. Note that we skip Default because we 
        # _always_ use it later (default is default!).
        if ($dir eq "." or $dir eq ".." or $dir eq "Default") {
            next;
        } else {
            print "Analyzing package set \"$dir\"\n" if $verbose;
            my $os = OSCAR::OCA::OS_Detect::open();
            # When we find a package set, we check if a package set is really
            # defined for the local distro. Note that the list of supported OPKG
            # supported by the local distro directly impact the list of avaiable
            # OPKGs, even if users wants to create images based on other distro.
            # This is normal, we must be sure the headnode provides all necessary
            # services (provided via OPKGs).
            my $distro_id = $os->{compat_distro}."-".$os->{compat_distrover}."-" .
                            $os->{arch} . ".xml";
            if ( -f "$package_set_dir/$dir/$distro_id") {
                print "Package set found: $dir\n" if $verbose;
                push (@packageSets, $dir);
            }
        }
    }
    closedir (DIRHANDLER);

    return @packageSets;
}

###############################################################################
# Give the set of OPKGs present in a specific package set
# Parameter: Package set name.
# Return:    List of OPKGs (array), undef if error.
###############################################################################
sub get_list_opkgs_in_package_set ($$) {
    my ($packageSetName, $distro_id) = @_;

    if ( ! -d $package_set_dir ) {
        carp "ERROR: The package set directory does not exist ".
             "($package_set_dir)";
        return undef;
    }
    my $file_path = "$package_set_dir/$packageSetName/$distro_id.xml";
    if ( ! -f $file_path) {
        carp "ERROR: Impossible to read the package set ($file_path)";
        return undef;
    }

    my @opkgs = ();

    # If the package set file exist, we parse the file
    open (FILE, "$file_path") 
        or (carp ("ERROR: impossible to open $file_path"), return undef);
    my $simple= XML::Simple->new (ForceArray => 1);
    my $xml_data = $simple->XMLin($file_path);
    my $base = $xml_data->{packages}->[0]->{opkg};
    print Dumper($xml_data) if $verbose;
    print "Number of OPKG in the $packageSetName package set: ".
          scalar(@{$base})."\n" if $verbose;
    for (my $i=0; $i < scalar(@{$base}); $i++) {
        my $opkg_name = $xml_data->{packages}->[0]->{opkg}->[$i];
        push (@opkgs, $opkg_name);
    }

    if ($verbose) {
        print "List of available OPKGs: ";
        OSCAR::Utils::print_array (@opkgs);
    }
    close (FILE);

    return @opkgs;
}

###############################################################################
# Give the set of OPKGs (with their full path) present in a specific package 
# set.
# This is used when other OSCAR components wants to check that the directory 
# for a specific OPKG exists (e.g. OPD related stuff)
# Parameter: Package set name.
# Return:    List of OPKGs, undef if error.
###############################################################################
sub get_opkgs_path_from_package_set ($) {
    my ($packageSetName) = @_;

    (carp ("ERROR: The package set directory does not exist ($package_set_dir)",
     return undef)) if ( ! -d $package_set_dir );
    my $os = OSCAR::OCA::OS_Detect::open();
    my $distro_id = $os->{compat_distro}."-".$os->{compat_distrover}."-".
                    $os->{arch} . ".xml";
    my $file_path = "$package_set_dir/$packageSetName/$distro_id";
    (carp ("ERROR: Impossible to read the package set ($file_path)",
     return undef)) if ( ! -f $file_path);

    my @opkgs = ();

    # If the package set file exist, we parse the file
    open (FILE, "$file_path");
    my $simple= XML::Simple->new (ForceArray => 1);
    my $xml_data = $simple->XMLin($file_path);
    my $base = $xml_data->{packages}->[0]->{opkg};
    print Dumper($xml_data) if $verbose;
    print "Number of OPKG in the $packageSetName package set: ".
          scalar(@{$base})."\n" if $verbose;
    # When we have the list of OPKG, we check that the directories exist
    print "Validating package set $packageSetName...\n" if $verbose;
    my $opkg_directory = $ENV{OSCAR_HOME}."/packages/";
    for (my $i=0; $i < scalar(@{$base}); $i++) {
        my $opkg_name = $xml_data->{packages}->[0]->{opkg}->[$i];
        my $dir = $opkg_directory . $opkg_name;
        if ( -d $dir) {
            print "Package $opkg_name valid...\n" if $verbose;
            push (@opkgs, $dir);
        } else {
            print "Package $opkg_name is not valid, we exclude it ($dir)\n"
                if $verbose;
        }
    }

    print "List of available OPKGs: ";
    print_array (@opkgs);
    return @opkgs;
}
