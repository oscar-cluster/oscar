package OSCAR::Distro;

#   $Id: Distro.pm,v 1.10 2003/07/10 16:50:22 brechin Exp $

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

# Copyright (c) 2003 NCSA
#                    Neil Gorsuch <ngorsuch@ncsa.uiuc.edu>

#   Copyright 2002 International Business Machines
#                  Sean Dague <japh@us.ibm.com>
# Copyright © 2003, The Board of Trustees of the University of Illinois. All rights reserved.

use strict;
use vars qw($VERSION @EXPORT);
use Carp;
use base qw(Exporter);
@EXPORT = qw(which_distro which_distro_server);

$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

my $DISTROFILES = {
                   'mandrake-release' => 'mandrake',
                   'redhat-release'   => 'redhat',
		   'aaa_version'      => 'suse',
		   'redhat-release-as'=> 'rhas',
                  };

############################################################
#  
#  which_distro($directory) - this returns the name and version of a distribution
#                             based on the contents of an directory of rpms
#
############################################################


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
    return (lc $name, lc $version);
}

############################################################
#
#  which_distro_server - this returns the distribution version and name of
#                        the running server.
#
############################################################


sub which_distro_server {
    my $name = "UnkownLinux";
    my $version = "0";
    foreach my $file (keys %$DISTROFILES) {
        my $output = `rpm -q --qf '\%{VERSION}' $file 2>/dev/null`;
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
    return (lc $name, lc $version);
}

1;
