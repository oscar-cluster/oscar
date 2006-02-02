package OSCAR::PackagePath;
#
# Copyright (c) 2006 Erich Focht efocht@hpce.nec.com>
#                    All rights reserved.
# 
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
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Had to split this out of Package because it is needed during the prereqs
# install which happens such early that we cannot guarantee that XML::Simple
# (required by OSCAR::Package) is already available.
#
# Build repository paths depending on distro, version, etc...

use strict;
use vars qw(@EXPORT);
use base qw(Exporter);
use Carp;

@EXPORT = qw(distro_repo_path oscar_repo_path);

#
# The URL where distribution packages are stored. When the files are
# stored locally they should go to:
# /tftpboot/distro/$distro-$version-$arch
# Doing this without subtrees of dirs has the advantage to immediately show
# the admin how many of these disk space consuming distro repositories are
# around.
#
# If the nodes have connectivity to the internet one could use a publicly
# accessible URL for the distro files. In that case place the URL of the
# repository (yum or apt) into the file
# /tftpboot/distro/$distro-$version-$arch.url
#
sub distro_repo_url {
    my ($distro, $distro_version, $arch) = @_;
    my $path = "/tftpboot/distro/$distro-$distro_version-$arch";
    if (-f "$path.url") {
	local *IN;
	if (open IN, "$path.url") {
	    my $line = <IN>;
	    chomp $line;
	    close IN;
	    $url = $line;
	}
    } else {
	$url = $path;
	if (! -d $path) {
	    !system("mkdir -p $path") or
		carp "Could not create directory $path!";
	}
    }
    return $url;
}

#
# The URL where OSCAR packages for a particular distro/version/arch
# combination are stored. This path is defined as:
# /tftpboot/oscar/$distro-$version-$arch
#
# The distro and version names used are those detected as "compat_distro"
# and "compat_distrover" in the OCA::OS_Detect framework. The reason is that
# OSCAR doesn't care about the particular flavor of a rebuilt distro, it
# uses the same packages eg. for rhel4, scientific linux 4 and centos 4.
#
sub oscar_repo_path {
    my ($distro, $distro_version, $arch) = @_;
    my $path = "/tftpboot/oscar/$distro-$distro_version-$arch";
    if (! -d $path) {
	!system("mkdir -p $path") or
	    carp "Could not create directory $path!";
    }
    return $path;
}

1;
