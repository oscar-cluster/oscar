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
use vars qw(@EXPORT @PKG_SOURCE_LOCATIONS);
use base qw(Exporter);
use OSCAR::OCA::OS_Detect;
use Carp;

@EXPORT = qw(distro_repo_url oscar_repo_path
	     pkg_extension pkg_separator
	     distro_detect_or_die);

# The possible places where packages may live.  

@PKG_SOURCE_LOCATIONS = ( "$ENV{OSCAR_HOME}/packages", 
                          "/var/lib/oscar/packages",
                        );


#
# Return an OS_Detect hash reference or die.
# Argument: $img
#           - if undefined, will detect distro of "/" on the current machine
#           - if set, will detect distro of the image located in that path
# Failure to detect the distro is a catastrophic event, so the program
# deserves to die.
#
# This routine might move to OSCAR::Distro when things stabilize...
#
sub distro_detect_or_die {
    my ($img) = @_;
    my $os = OSCAR::OCA::OS_Detect::open($img);
    die "Unable to determine operating system for $img" if (!$os);
    return $os;
}

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
    my ($img) = @_;   # can be undefined, in which case we query "/"
    my $os = distro_detect_or_die($img);
    my $distro    = $os->{distro};
    my $distrover = $os->{distro_version};
    my $arch      = $os->{arch};
    my $path = "/tftpboot/distro/$distro-$distrover-$arch";
    my $url;
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
	    print STDERR "Distro repository $path not found. Creating empty directory.\n";
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
    my ($img) = @_;   # can be undefined, in which case we query "/"
    my $os = distro_detect_or_die($img);
    my $cdistro   = $os->{compat_distro};
    my $cdistrover= $os->{compat_distrover};
    my $arch      = $os->{arch};
    my $path = "/tftpboot/oscar/$cdistro-$cdistrover-$arch";
    if (! -d $path) {
	print STDERR "OSCAR repository $path not found. Creating empty directory.\n";
	!system("mkdir -p $path") or
	    carp "Could not create directory $path!";
    }
    return $path;
}

#
# returns the package extension used for the packages in an image (or "/")
#
sub pkg_extension {
    my ($img) = @_;   # can be undefined, in which case we query "/"
    my $os = distro_detect_or_die($img);
    my $pkg = $os->{pkg};
    if ($pkg =~ /^rpm$/) {
	return ".rpm";
    } elsif ($pkg =~ /^deb$/) {
	return ".deb";
    } else {
	return undef;
    }
}

#
# returns the package separator string used for packages in an image (or "/")
#
sub pkg_separator {
    my ($img) = @_;   # can be undefined, in which case we query "/"
    my $os = distro_detect_or_die($img);
    my $pkg = $os->{pkg};
    if ($pkg =~ /^rpm$/) {
	return "-";
    } elsif ($pkg =~ /^deb$/) {
	return "_";
    } else {
	return undef;
    }
}

1;
