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
use File::Basename;
use Carp;

@EXPORT = qw(distro_repo_url oscar_repo_url repo_empty
	     pkg_extension pkg_separator
	     distro_detect_or_die list_distro_pools);

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
    my ($img,$os);
    if (scalar(@_) <= 1) {
	($img) = @_;
    } elsif ($_[0] eq "os") {
	$os = $_[1];
    }
    if (!defined($os)) {
	$os = distro_detect_or_die($img);
    }
    my $distro    = $os->{distro};
    my $distrover = $os->{distro_version};
    my $arch      = $os->{arch};
    my $path = "/tftpboot/distro/$distro-$distrover-$arch";
    my $url;
    if (-f "$path.url") {
	my @remote;
	local *IN;
	if (open IN, "$path.url") {
	    while (my $line = <IN>) {
		chomp $line;
		next if ($line !~ /^(http|ftp|file|mirror)/);
		next if (($line =~ /^\s*$/) || ($line =~ /^\s*#/));
		push @remote, $line;
	    }
	    close IN;
	    $url = join(",",@remote);
	}
    } else {
	$url = $path;
	if ( (! -d $path) && (! -l $path) ) {
	    # check if /tftpboot/rpm exists and has the distro we expect
	    my $oldpool = "/tftpboot/rpm";
	    if ( -d $oldpool || -l $oldpool) {
		my $ros = OSCAR::OCA::OS_Detect::open(pool => $oldpool);
		if (defined($ros) && (ref($ros) eq "HASH") &&
		    ($ros->{distro} eq $os->{distro}) &&
		    ($ros->{distro_version} eq $os->{distro_version}) &&
		    ($ros->{arch} eq $os->{arch}) ) {
		    print "Discovered correct distro repository in $oldpool!\n";
		    print "Linking it symbolically to $path.\n";
		    my $pdir = dirname($path);
		    if (! -d $pdir) {
			!system("mkdir -p $pdir") or
			    croak "Could not make directory $pdir $!";
		    }
		    !system("ln -s $oldpool $path") or
			croak "Could not link $oldpool to $path: $!";
		    return $url;
		}
	    }
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
# Similar to the distro url, one can use a file called 
# /tftpboot/oscar/$distro-$version-$arch.url
# containing a list of URLs pointing at the repositories to be scanned for
# OSCAR packages. This allows having repositories located on the internet.
#
# The distro and version names used are those detected as "compat_distro"
# and "compat_distrover" in the OCA::OS_Detect framework. The reason is that
# OSCAR doesn't care about the particular flavor of a rebuilt distro, it
# uses the same packages eg. for rhel4, scientific linux 4 and centos 4.
#
# Usage:
#    $path = oscar_repo_url();         # detect distro of master ("/")
#    $path = oscar_repo_url($image);   # detect distro of image
#    $path = oscar_repo_url(os => $os);  # use given $os structure
#
# Usage logic:
# If a .url file exists, use the URLs listed inside.
# Otherwise expect local repositories to exist in the standard place. If the
# local repositories don't exist, create their directories.
#
sub oscar_repo_url {
    my ($img,$os);
    if (scalar(@_) <= 1) {
	($img) = @_;
    } elsif ($_[0] eq "os") {
	$os = $_[1];
    }
    if (!defined($os)) {
	$os = distro_detect_or_die($img);
    }
    my $cdistro   = $os->{compat_distro};
    my $cdistrover= $os->{compat_distrover};
    my $arch      = $os->{arch};
    my $path = "/tftpboot/oscar/$cdistro-$cdistrover-$arch";
    my $commons = "/tftpboot/oscar/common-" . $os->{pkg} . "s";
    my $url = $commons . "," . $path;
    if (-f "$path.url") {
	my @remote;
	local *IN;
	if (open IN, "$path.url") {
	    while (my $line = <IN>) {
		chomp $line;
		next if ($line !~ /^(http|ftp|file|mirror):/);
		push @remote, $line;
	    }
	    close IN;
	    return join(",",@remote);
	}
    } else {
	if (! -d $path) {
	    print STDERR "Distro repository $path not found. Creating empty directory.\n";
	    !system("mkdir -p $path") or
		carp "Could not create directory $path!";
	}
	if (! -d $commons) {
	    print STDERR "Commons repository $commons not found. Creating empty directory.\n";
	    !system("mkdir -p $commons") or
		carp "Could not create directory $commons!";
	}
    }
    return $url;
}

#
# Check if local repo directory is empty.
# Returns 1 (true) if directory is empty.
#
sub repo_empty {
    my ($path) = @_;
    my $entries = 0;
    local *DIR;
    opendir DIR, $path or carp "Could not read directory $path!";
    for my $d (readdir DIR) {
	next if ($d eq "." || $d eq "..");
	$entries++ if (-f $d || -d $d);
    }
    return ($entries ? 0 : 1);
}

#
# List all available distro pools or distro URL files
#
sub list_distro_pools {
    my $ddir = "/tftpboot/distro";
    # recognised architectures
    my $arches = "i386|x86_64|ia64";
    my %pools;
    local *DIR;
    opendir DIR, $ddir or carp "Could not read directory $ddir!";
    for my $e (readdir DIR) {
	if ($e =~ /(.*)\-(\d+)\-($arches)(|\.url)$/) {
	    my $distro = "$1-$2-$3";
	    my $os;
	    if ($4) {
		$os = OSCAR::OCA::OS_Detect::open(fake=>{distro=>$1,
							 distro_version=>$2,
							 arch=>$3, }
						  );
	    } else {
		$os = OSCAR::OCA::OS_Detect::open(pool=>"$ddir/$e");
	    }
	    if (defined($os) && (ref($os) eq "HASH")) {
		$pools{$distro}{os} = $os;
		$pools{$distro}{oscar_repo} = &oscar_repo_url(os=>$os);
		$pools{$distro}{distro_repo} = &distro_repo_url(os=>$os);
		if ($4) {
		    $pools{$distro}{url} = "$ddir/$e";
		} else {
		    $pools{$distro}{path} = "$ddir/$e";
		}		    
	    }
	}
    }
    return %pools;
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
