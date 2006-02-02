#!/usr/bin/env perl
#
# Copyright (c) 2005 Oak Ridge National Laboratory.
#                    All rights reserved.
#
# Copyright (c) Erich Focht <efocht@hpce.nec.com>
#                    All rights reserved.
# 
# This file is part of the OSCAR software package.  For license
# information, see the COPYING file in the top level directory of the
# OSCAR source distribution.
#
# $Id$
#

package OCA::OS_Detect::Debian;

use strict;

my $DEBUG = 1 if( $ENV{DEBUG_OCA_OS_DETECT} );


# query returns a reference to the ID hash or undef if the current package
# doesn't fit to the queried distribution
sub query {
    my %opt = @_;
    if (exists($opt{chroot})) {
	if (-d $opt{chroot}) {
	    return detect($opt{chroot});
	} else {
	    print STDERR "WARNING: Path $opt{chroot} does not exist!\n";
	    return undef;
	}
    } else {
	return detect("/");
    }
}

# This routine is cheap and called very rarely, so don't care for
# unnecessary buffering. Simply recalculate $id each time this is
# called.
sub detect {
    my ($root) = @_;
    my $release_string;

    # If /etc/debian_version exists, continue, otherwise, quit.
    if (-f "$root/etc/debian_version") {
	local *FH;
	open(FH, "$root/etc/debian_version") or
	    die "Error: unable to open $root/etc/debian_version $!\n";
	my @file = grep { ! /^\s*\#/ } <FH>;
	close(FH);

	# 
	# Get version from one-line entry giving the version number in the
	# file "/etc/debian_version".  c.f.,
	# http://www.debian.org/doc/FAQ/ch-software.en.html#s-isitdebian
	#
	my $deb_ver = $file[0];
	chomp($deb_ver);
    } else {
	return undef;
    }

    # this hash contains all info necessary for identifying the OS
    my $id = {
	os => "linux",
	chroot => $root,
    };

    #
    # Now do some checks to make sure we're supported
    #

    # Limit support to only Debian v3.1 (sarge)
    my $deb_update;
    $deb_ver =~ /^(\d+)\.(\d+)/;
    $deb_ver = $1;
    $deb_update = $2;
    if ($deb_ver != 3) {
	print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Debian version support - ($deb_ver)\n\n" if( $DEBUG );
	return undef;
    }

    # determine architecture
    my $arch = detect_arch($root);
    $id->{arch} = $arch;

    # Limit support to only x86 machines
    if ($arch !~ /^i686$|^i586$|^i386$/ ) {
	print "OCA::OS_Detect::Debian-";
	print "DEBUG: Failed Architecture support - ($arch)\n\n" if( $DEBUG );
	return 0;
    }

    $id->{distro} = "debian";
    $id->{distro_flavor} = "sarge";
    $id->{distro_version} = $deb_ver;
    $id->{distro_update} = $deb_update;
    $id->{compat_distro} = "debian";
    $id->{compat_distrover} = $deb_ver;
    $id->{pkg} = "deb";

    # Make final string
    $id->{ident} = "$id->{os}-$id->{arch}-$id->{distro}-$id->{distro_version}-$id->{distro_update}";
    return $id;
}

# Determine architecture by checking the executable type of a wellknown
# program
sub detect_arch {
    my ($root) = @_;
    my $arch="unknown";
    my $q = `env LC_ALL=C file $root/bin/bash`;
    if ($q =~ m/executable,\ \S+\ (\S+),\ version/) {
	$arch = $1;
	if ($arch =~ m/386$/) {
	    $arch = "i386";
	}
    }
    return $arch;
}

# If we got here, we're happy
1;
