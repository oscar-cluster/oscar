package OSCAR::Distro;

#   $Id$

#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
 
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
 
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Copyright 2005 Bernard Li <bli@bcgsc.ca>
#
# Copyright 2005 Erich Focht <efocht@hpce.nec.com>
#
# Copyright 2004 Revolution Linux
#           Benoit des Ligneris <bdesligneris@revolutionlinux.com>
# Copyright (c) 2003 NCSA
#                    Neil Gorsuch <ngorsuch@ncsa.uiuc.edu>
# Copyright 2002 International Business Machines
#                  Sean Dague <japh@us.ibm.com>
# Copyright � 2003, The Board of Trustees of the University of Illinois. 
#                   All rights reserved.
# Copyright (c) 2005, Revolution Linux
# Copyright (c) 2007 The Trustees of Indiana University.  
#                    All rights reserved.
# Copyright (c) 2007, Oak Ridge National Laboratory.
#                     Geoffroy R. Vallee <valleegr@ornl.gov>
#                     All rights reserved.

use strict;
use vars qw($VERSION @EXPORT);
use Carp;
use OSCAR::Logger;
use OSCAR::LoggerDefs;
use OSCAR::ConfigFile;
use OSCAR::Utils;
use OSCAR::PackagePath;
use OSCAR::OCA::OS_Detect;
use warnings "all";
use base qw(Exporter);
@EXPORT = qw(
            find_distro
            get_list_of_supported_distros
            get_list_of_supported_distros_id
            is_a_valid_distro_id
            which_distro
            which_distro_server
            which_mysql_name
            );

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);
my $tftpdir = "/tftpboot/";
my $supported_distro_file;
if (defined ($ENV{OSCAR_HOME})) {
    $supported_distro_file = "$ENV{OSCAR_HOME}/share/etc/supported_distros.txt";
} else {
    $supported_distro_file = "/etc/oscar/supported_distros.txt";
}

my $DISTROFILES = {
		   'fedora-release'        => 'fedora',
		   'yellowdog-release'     => 'yellowdog',
		   'mandrake-release'      => 'mandrake',
		   'mandrakelinux-release' => 'mandrake',
		   'mandriva-release'	   => 'mandriva',
		   'redhat-release'        => 'redhat',
		   'aaa_version'           => 'suse',
		   'aaa_base'	           => 'suse',
		   'debian_version'        => 'debian',
		   'sl-release'            => 'sl',      # Scientific Linux
		   'centos-release'        => 'centos',
                  };

############################################################
#  
#  which_distro($directory) - this returns the name and version of a distribution
#                             based on the contents of an directory of rpms
#
############################################################

# XXX: For Debian we're going to have to pull /etc/debian_version out of
# base-files*.deb to figure out what release we're on... wow, that sucks
#
# This flavor of the function is _only_ called from
# packages/kernel_picker/scripts/pre_configure and scripts/oscar_wizard
#
# TODO: why do we need that? OS_Detect should do that!
sub which_distro {
    my $directory = shift;
    my $version = "0.0";
    my $name = "UnknownLinux";
    foreach my $file (keys %$DISTROFILES) {
        my $output = `rpm -q --qf '\%{VERSION}' -p $directory/$file*`;
        if($output =~ /^([\w\.]+)/) {
            $version = $1;
            $name = $DISTROFILES->{$file};
            last;
        }
    }
    # special treatment for RHEL
    if ($name eq "redhat") {
	if ($version =~ m/^3(ES|AS|WS)/) {
	    $version = "3as";
	} elsif ($version =~ m/^4(ES|AS|WS)/) {
	    $version = "el4";
	}
    }
    # RHEL clones look like RHEL
    if ($name eq "sl" || $name eq "centos") {
	$name = "redhat";
	if ($version =~ /^3/) {
	    $version = "3as";
	} elsif ($version =~ /^4/) {
	    $version = "el4";
	}
    }
  
    return (lc $name, lc $version);
}

############################################################
#
#  which_distro_server - this returns the distribution version and name of
#                        the running server.
#
# TODO: why do we need that? OS_Detect should do that!
############################################################
sub which_distro_server {
    my $name = "UnknownLinux";
    my $version = "0";
    foreach my $file (keys %$DISTROFILES) {
        my $output = $DISTROFILES->{$file} eq 'debian' ?
                        `cat /etc/$file 2>/dev/null` :
                        `rpm -q --qf '\%{VERSION}' $file 2>/dev/null`;

        if($?) {
            # Then the child had a bad exit, so the package is not here
            next;
        }
        $version = $output;
        $name = $DISTROFILES->{$file};
	if ($name eq "suse") { 
		$version = `cat /etc/SuSE-release | tail -1 | cut -d '=' -f 2 | cut -b 2-`;
		chomp $version;
	}
        last;
    }
    # special treatment for RHEL
    if ($name eq "redhat") {
	if ($version =~ m/^3(ES|AS|WS)/) {
	    $version = "3as";
	} elsif ($version =~ m/^4(ES|AS|WS)/) {
	    $version = "el4";
	}
    }
    # RHEL clones look like RHEL
    if ($name eq "sl" || $name eq "centos") {
	$name = "redhat";
	if ($version =~ /^3/) {
	    $version = "3as";
	} elsif ($version =~ /^4/) {
	    $version = "el4";
	}
    }
    return (lc $name, lc $version);
}

############################################################
#
#  which_mysql_name - this returns the name of the mysql service
#                     of the distribution
#
# TODO: that should be replaced by OS_Settings
############################################################
sub which_mysql_name ($$) {
	my $name = shift;
	my $version = shift;

CASE: {
	      # redhat
	      ($name eq "redhat") && do{
		      return "mysqld";
		      last CASE;
	      };

	      # fedora
	      ($name eq "fedora") && do{
		      return "mysqld";
		      last CASE;
	      };

	      # yellowdog 
	      ($name eq "yellowdog") && do{
		      return "mysqld";
		      last CASE;
	      };

	      # mandrake
	      ($name eq "mandrake") && do{
		      return "mysql";
		      last CASE;
	      };

	      # mandriva
	      ($name eq "mandriva") && do{
		      return "mysqld";
		      last CASE;
	      };

	      # suse
	      ($name eq "suse") && do{
		      return "mysql";
		      last CASE;
	      };

	      # suse
	      ($name eq "debian") && do{
		      return "mysql";
		      last CASE;
	      };


      }

}

# Parse a basic configuration file organized by blocks. A block starts by its
# name in between "[" and "]". From a position, it returns the position of the
# next block
#
# Input: current_pos, the position in the file from which we want to start the
#                     search (position in term of lines).
#        array, content of the file (result of my @data = <FILE>;
# Return: the position of the next block if success, -1 else.
sub get_position_of_next_release_entry ($@) {
    my ($current_pos, @array) = @_;
    my $i = $current_pos;
    while (($i < scalar(@array))) {
        my $str = $array[$i];
        if ($str =~ /^\[(.*)\]$/) {
            last;
        }
        $i++;
    }
    if ($i == scalar(@array)) {
        return -1;
    } else {
        return $i;
    }
}

################################################################################
# Return: an array with the list of distros that OSCAR supports. Each element  #
#         in the array is like: debian-4-x86_64 or rhel-5.1-x86_64.            #
#         Returns undef if error.                                              #
################################################################################
sub get_list_of_supported_distros {
    my @list;

    # we get the OSCAR version
    my $version = OSCAR::Utils::get_oscar_version();
    if (!defined $version) {
        oscar_log(6, ERROR, "Impossible to get the OSCAR version");
        return undef;
    }

    # we try to find a match
    # FIXME: Error are not handeled.....
    my %supported_distros = OSCAR::ConfigFile::get_all_values ("$supported_distro_file", "$version");

    foreach my $key ( keys %supported_distros ) {
        unshift (@list, $key);
    }

    return @list;
}

################################################################################
# Return an array with the list of distro IDs that OSCAR supports. Each        #
# element in the array is like: debian, centos or rhel.                        #
################################################################################
sub get_list_of_supported_distros_id {
    my @distros = get_list_of_supported_distros();
    my @distros_id;
    foreach my $d (@distros) {
        my ($id, $rest) = split (/-/, $d);
        if ($id ne "" && !OSCAR::Utils::is_element_in_array($id, @distros_id)) {
            push (@distros_id, $id);
        }
    }
    return @distros_id;
}

################################################################################
# Find information about a given Linux distribution in the config file for     #
# supported distros. This is a basic function to get for instance the default  #
# repositories (distribution and OSCAR repositories).                          #
#                                                                              #
# Input: distro, the distro id you are looking for (with the OS_Detect syntax).#
# Return: hash which has the following format                                  #
# {                                                                            #
# 'default_distro_repos' => ['http://ftp.us.debian.org/debian/+etch+main'],     #
# 'name' => 'debian-4-x86_64',                                               #
# 'default_oscar_repo' => ['http://oscar.gforge.inria.fr/debian/+stable+oscar']#
# }                                                                            #
################################################################################
sub find_distro ($) {
    my $distro_name = shift;
    my %hash;
    $hash{'name'} = $distro_name;

    # we get the OSCAR version
    my $version = OSCAR::Utils::get_oscar_version();

    my %supported_distros = OSCAR::ConfigFile::get_all_values ("$supported_distro_file", "$version");

    # we try to find a match
    my $repo_string = $supported_distros{$distro_name};
    if( ! defined($repo_string)) {
        oscar_log(5, ERROR, "Unsupported distro: ($distro_name).\nSee $supported_distro_file");
        return undef;
    }
    chomp ($repo_string);
    my @default_distro_repos;
    my @default_oscar_repos;
    my @repos = split (" ", $repo_string);
    foreach my $r (@repos) {
        if ($r =~ /distro:(.*)/) {
            push(@default_distro_repos,$1);
            #push(@{$hash{'default_distro_repos'}},$1);
            #$hash{'default_distro_repos'} .= "$1\n";
        } elsif ($r =~ /oscar:(.*)/) {
            push(@default_oscar_repos,$1);
            #push(@{$hash{'default_oscar_repos'}},$1);
            #$hash{'default_oscar_repo'} = $1;
        } else {
            oscar_log(6, ERROR, "Unknown repo type ($r)");
            return undef;
        }
    }
    $hash{'default_distro_repos'} = \@default_distro_repos;    
    $hash{'default_oscar_repos'}  = \@default_oscar_repos;    
    return %hash;
}

################################################################################
# Tests if a Linux distribution ID is valid or not.                            #
#                                                                              #
# Input: distro_id, the distro id (following the OS_Detect syntax).            #
# Return: 1 if the distro id is valid, 0 else.                                 #
################################################################################
sub is_a_valid_distro_id ($) {
    my $distro_id = shift;
    my ($dist, $ver, $arch) 
        = OSCAR::PackagePath::decompose_distro_id ($distro_id);
    if (!OSCAR::Utils::is_a_valid_string ($dist) ||
        !OSCAR::Utils::is_a_valid_string ($ver) ||
        !OSCAR::Utils::is_a_valid_string ($arch)) {
        return 0;
    }
    my $os = OSCAR::OCA::OS_Detect::open (fake=>{distro=>$dist,
                                                 distro_version=>$ver,
                                                 arch=>$arch});
    if (defined $os && ref($os) eq "HASH") {
        return 1;
    } else {
        return 0;
    }
}    

1;
