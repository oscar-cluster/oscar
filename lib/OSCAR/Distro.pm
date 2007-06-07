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
#

# Copyright (c) 2003 NCSA
#                    Neil Gorsuch <ngorsuch@ncsa.uiuc.edu>

#   Copyright 2002 International Business Machines
#                  Sean Dague <japh@us.ibm.com>
# Copyright © 2003, The Board of Trustees of the University of Illinois. All rights reserved.
# Copyright (c) 2005, Revolution Linux
# Copyright (c) 2007 The Trustees of Indiana University.  
#                    All rights reserved.

use strict;
use vars qw($VERSION @EXPORT);
use Carp;
use base qw(Exporter);
@EXPORT = qw(which_distro which_distro_server which_mysql_name);

$VERSION = sprintf("r%d", q$Revision$ =~ /(\d+)/);

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
############################################################
sub which_mysql_name {
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

1;
